# frozen_string_literal: true

class DataciteDoi < Doi
  include Elasticsearch::Model

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "dois-#{ENV['ES_PREFIX']}"
  else
    index_name "dois"
  end
  # TODO switch index
  # if Rails.env.test?
  #   index_name "dois-datacite-test"
  # elsif ENV["ES_PREFIX"].present?
  #   index_name"dois-datacite-#{ENV["ES_PREFIX"]}"
  # else
  #   index_name "dois-datacite"
  # end

  # TODO remove query for type once STI is enabled
  def self.import_by_ids(options = {})
    index =
      if Rails.env.test?
        index_name
      elsif options[:index].present?
        options[:index]
      else
        inactive_index
      end
    from_id =
      (options[:from_id] || DataciteDoi.where(type: "DataciteDoi").minimum(:id)).
        to_i
    until_id =
      (
        options[:until_id] ||
          DataciteDoi.where(type: "DataciteDoi").maximum(:id)
      ).
        to_i
    count = 0

    # TODO remove query for type once STI is enabled
    # SQS message size limit is 256 kB, up to 2 GB with S3
    DataciteDoi.where(type: "DataciteDoi").where(id: from_id..until_id).
      find_in_batches(batch_size: 100) do |dois|
      mapped_dois = dois.map do |doi|
        { "id" => doi.id, "as_indexed_json" => doi.as_indexed_json }
      end
      DataciteDoiImportInBulkJob.perform_later(mapped_dois, index: index)
      count += dois.length
    end

    logger.info "Queued importing for DataCite DOIs with IDs #{from_id}-#{until_id}."
    count
  rescue Aws::SQS::Errors::RequestEntityTooLarge => e
    Rails.logger.error "[Elasticsearch] Error #{e.class}: #{mapped_dois.bytesize} bytes"
  end

  def self.import_by_client(client_id)
    return nil if client_id.blank?

    # TODO remove query for type once STI is enabled
    DataciteDoi.where(type: "DataciteDoi").where(datacentre: client_id).
      find_in_batches(batch_size: 250) do |dois|
      mapped_dois = dois.map do |doi|
        { "id" => doi.id, "as_indexed_json" => doi.as_indexed_json }
      end
      DataciteDoiImportInBulkJob.perform_later(mapped_dois, index: self.active_index)
    end
  rescue Aws::SQS::Errors::RequestEntityTooLarge => e
    Rails.logger.error "[Elasticsearch] Error #{e.class}: #{mapped_dois.bytesize} bytes"
  end

  def self.import_in_bulk(dois, options = {})
    index =
      if Rails.env.test?
        index_name
      elsif options[:index].present?
        options[:index]
      else
        inactive_index
      end
    errors = 0
    count = 0

    response =
      DataciteDoi.__elasticsearch__.client.bulk index: index,
                                                type:
                                                  DataciteDoi.document_type,
                                                body:
                                                  dois.map { |doi|
                                                    {
                                                      index: {
                                                        _id: doi["id"],
                                                        data:
                                                          doi["as_indexed_json"],
                                                      },
                                                    }
                                                  }

    # report errors
    errors_in_response =
      response["items"].select { |k, _v| k.values.first["error"].present? }
    errors += errors_in_response.length
    errors_in_response.each do |item|
      Rails.logger.error "[Elasticsearch] " + item.inspect
    end

    count += dois.length

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{
                           count
                         } DataCite DOIs."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{
                          count
                        } DataCite DOIs."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
    Aws::SQS::Errors::RequestEntityTooLarge,
    Faraday::ConnectionFailed,
    ActiveRecord::LockWaitTimeout => e

    Rails.logger.error "[Elasticsearch] Error #{e.class} with message #{
                   e.message
                 } importing DataCite DOIs."
  end
end
