# frozen_string_literal: true

class DataciteDoi < Doi
  include Elasticsearch::Model

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test#{ENV['TEST_ENV_NUMBER']}"
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
    batch_size = options[:batch_size] || 50
    count = 0

    # TODO remove query for type once STI is enabled
    # SQS message size limit is 256 kB, up to 2 GB with S3
    DataciteDoi
      .where(type: "DataciteDoi")
      .where(id: from_id..until_id)
      .find_in_batches(batch_size: batch_size) do |dois|
        ids = dois.pluck(:id)
        DataciteDoiImportInBulkJob.perform_later(ids, index: index)
        count += ids.length
      end

    Rails.logger.info "Queued importing for DataCite DOIs with IDs #{from_id}-#{until_id}."
    count
  end

  def self.import_by_client(client_id)
    if client_id.blank?
      Rails.logger.error "Missing client ID."
      exit
    end

    client = ::Client.where(deleted_at: nil).where(symbol: client_id).first
    if client.nil?
      Rails.logger.error "Repository not found for client ID #{client_id}."
      exit
    end

    # import DOIs for client
    Rails.logger.info "Started import of #{client.dois.count} DOIs for repository #{client_id}."

    DataciteDoi.where(datacentre: client.id).
      find_in_batches(batch_size: 50) do |dois|
      ids = dois.pluck(:id)
      DataciteDoiImportInBulkJob.perform_later(ids, index: self.active_index)
    end
  end

  def self.import_in_bulk(ids, options = {})
    index =
      if Rails.env.test?
        index_name
      elsif options[:index].present?
        options[:index]
      else
        inactive_index
      end
    errors = 0

    # get database records from array of database ids
    dois = DataciteDoi.where(id: ids).include(:metadata)

    response =
      DataciteDoi.__elasticsearch__.client.bulk index: index,
                                                type:
                                                  DataciteDoi.document_type,
                                                body:
                                                  dois.map { |doi|
                                                    {
                                                      index: {
                                                        _id: doi.id,
                                                        data:
                                                          doi.as_indexed_json,
                                                      },
                                                    }
                                                  }

    # report errors
    if response["errors"]
      errors_in_response =
        response["items"].select { |k, _v| k.values.first["error"].present? }
      errors += errors_in_response.length
      errors_in_response.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
      end
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{
                          dois.length
                         } DataCite DOIs."
    elsif dois.length > 0
      Rails.logger.debug "[Elasticsearch] Imported #{
                         dois.length
                        } DataCite DOIs."
    end

    dois.length
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
    Aws::SQS::Errors::RequestEntityTooLarge,
    Faraday::ConnectionFailed,
    ActiveRecord::LockWaitTimeout => e

    Rails.logger.error "[Elasticsearch] Error #{e.class} with message #{
                   e.message
                 } importing DataCite DOIs."
  end
end
