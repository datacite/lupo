# frozen_string_literal: true

class OtherDoi < Doi
  include Elasticsearch::Model

  # use different index for testing
  if Rails.env.test?
    index_name "dois-other-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "dois-other-#{ENV['ES_PREFIX']}"
  else
    index_name "dois-other"
  end

  def client_id=(_value)
    write_attribute(:datacentre, 0)
  end

  def set_defaults
    self.is_active = aasm_state == "findable" ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 1
    self.updated = Time.zone.now.utc.iso8601
    self.datacentre = 0
  end

  # Transverses the index in batches and using the cursor pagination and executes a Job that matches the query and filter
  # Options:
  # +filter+:: paramaters to filter the index
  # +label+:: String to output in the logs printout
  # +query+:: ES query to filter the index
  # +job_name+:: Acive Job class name of the Job that would be executed on every matched results
  def self.loop_through_dois(options = {})
    size = (options[:size] || 1_000).to_i
    filter = options[:filter] || {}
    label = options[:label] || ""
    options[:job_name] ||= ""
    query = options[:query].presence

    if options[:cursor].present?
      timestamp, doi = options[:cursor].split(",", 2)
      cursor = [timestamp.to_i, doi]
    else
      cursor = []
    end

    response =
      OtherDoi.query(query, filter.merge(page: { size: 1, cursor: [] }))
    message = "#{label} #{response.results.total} other dois with #{label}."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.results.length.positive?
        response =
          OtherDoi.query(
            query,
            filter.merge(page: { size: size, cursor: cursor }),
          )
        break unless response.results.results.length.positive?

        Rails.logger.info "#{label} #{
                            response.results.results.length
                          } other dois starting with _id #{
                            response.results.to_a.first[:_id]
                          }."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "#{label} Cursor: #{cursor} "

        ids = response.results.results.map(&:uid)
        LoopThroughDoisJob.perform_later(ids, options)
      end
    end

    message
  end

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
      (options[:from_id] || OtherDoi.where(type: "OtherDoi").minimum(:id)).
        to_i
    until_id =
      (
        options[:until_id] || OtherDoi.where(type: "OtherDoi").maximum(:id)
      ).
        to_i
    count = 0

    # TODO remove query for type once STI is enabled
    DataciteDoi.where(type: "OtherDoi").where(id: from_id..until_id).
      find_in_batches(batch_size: 50) do |dois|
      ids = dois.pluck(:id)
      OtherDoiImportInBulkJob.perform_later(ids, index: index)
      count += ids.length
    end

    Rails.logger.info "Queued importing for Other DOIs with IDs #{from_id}-#{until_id}."
    count
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
    dois = OtherDoi.includes(
      :client,
      :media,
      :view_events,
      :download_events,
      :citation_events,
      :reference_events,
      :part_events,
      :part_of_events,
      :version_events,
      :version_of_events,
      :metadata
    ).where(id: ids, type: "OtherDoi")

    response =
      OtherDoi.__elasticsearch__.client.bulk index: index,
                                                type:
                                                  OtherDoi.document_type,
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
                         } Other DOIs."
    elsif dois.length > 0
      Rails.logger.debug "[Elasticsearch] Imported #{
                          dois.length
                        } Other DOIs."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
    Aws::SQS::Errors::RequestEntityTooLarge,
    Faraday::ConnectionFailed,
    ActiveRecord::LockWaitTimeout => e

    Rails.logger.error "[Elasticsearch] Error #{e.class} with message #{
                   e.message
                 } importing Other DOIs."
  end
end
