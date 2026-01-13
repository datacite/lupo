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
    index = options[:index] || inactive_index
    if Rails.env.test?
      index = index_name
    end
    from_id  = (options[:from_id]  || OtherDoi.where(type: "OtherDoi").minimum(:id)).to_i
    until_id = (options[:until_id] || OtherDoi.where(type: "OtherDoi").maximum(:id)).to_i
    shard_size = options[:shard_size] || 10_000
    batch_size = options[:batch_size] || 50
    return 0 if from_id.nil? || until_id.nil?
    count = 0
    (from_id..until_id).step(shard_size) do |start_id|
      end_id = [start_id + shard_size - 1, until_id].min
      OtherDoiBatchEnqueueJob.perform_later(start_id, end_id, batch_size: batch_size, index: index)
      count += 1
      Rails.logger.info "Queued batch (#{count}) of OtherDoiBatchEnqueueJob for Other DOIs with IDs #{start_id}-#{end_id}"
    end
    Rails.logger.info "Queued ALL OtherDois with IDs #{from_id}-#{until_id} in batches of size #{shard_size}."
    count
  end

  def self.upload_to_elasticsearch(index, bulk_body)
    number_of_dois = bulk_body.length
    errors = 0
    response =
      OtherDoi.__elasticsearch__.client.bulk index: index,
                                             type: OtherDoi.document_type,
                                             body: bulk_body

    # report errors
    if response["errors"]
      errors_in_response =
        response["items"].select { |k, _v| k.values.first["error"].present? }
      errors += errors_in_response.length
      errors_in_response.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
      end
    end

    if errors > 0
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{
                          number_of_dois
                         } Other DOIs."
    elsif number_of_dois > 0
      Rails.logger.debug "[Elasticsearch] Imported #{number_of_dois} Other DOIs."
    end

    number_of_dois
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
    Aws::SQS::Errors::RequestEntityTooLarge,
    Faraday::ConnectionFailed,
    ActiveRecord::LockWaitTimeout => e

    Rails.logger.error "[Elasticsearch] Error #{e.class} with message #{e.message} importing Other DOIs."
  end

  def self.import_in_bulk(ids, options = {})
    # Get optional parameters
    batch_size = options[:batch_size] || 50
    # default batch_size is 50 here in order to avoid creating a bulk request
    # to elasticsearch that is too large
    # With this the number of ids can be very large.

    index =
      if Rails.env.test?
        index_name
      elsif options[:index].present?
        options[:index]
      else
        inactive_index
      end

    # get database records from array of database ids
    selected_dois = OtherDoi.where(id: ids, type: "OtherDoi").includes(
      :client,
      :media,
      :metadata
    )
    selected_dois.find_in_batches(batch_size: batch_size) do |dois|
      # Preload all events for this batch in a single query
      EventsPreloader.new(dois).preload!
      
      bulk_body = dois.map do |doi|
        {
          index: {
            _id: doi.id,
            data: doi.as_indexed_json,
          },
        }
      end
      upload_to_elasticsearch(index, bulk_body)
    end
  end
end
