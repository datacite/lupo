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

  def self.index_all_by_client(options = {})
    client_to_doi_count = DataciteDoi.where(type: "DataciteDoi").group(:datacentre).count
    index = options[:index] || self.inactive_index
    batch_size = options[:batch_size] || 2000
    client_to_doi_count.keys.each do |client_id|
      DoiImportByClientJob.perform_later(
        client_id,
        index: index,
        batch_size: batch_size,
        skip_client_lookup: true
      )
    end
  end

  def self.import_by_ids(options = {})
    index = options[:index] || inactive_index
    if Rails.env.test?
      index = index_name
    end
    datacite_dois = DataciteDoi.select(:id).where(type: "DataciteDoi")
    from_id = (options[:from_id] || datacite_dois.minimum(:id)). to_i
    until_id = (options[:until_id] || datacite_dois.maximum(:id)). to_i
    shard_size = options[:shard_size] || 10_000
    batch_size = options[:batch_size] || 50
    return 0 if from_id.nil? || until_id.nil?
    count = 0
    (from_id..until_id).step(shard_size) do |start_id|
      end_id = [start_id + shard_size - 1, until_id].min
      DataciteDoiBatchEnqueueJob.perform_later(start_id, end_id, batch_size: batch_size, index: index)
      count += 1
      Rails.logger.info "Queued batch (#{count}) of DataciteDoiBatchEnqueueJob for DataciteDois with IDs #{start_id}-#{end_id}"
    end
    Rails.logger.info "Queued ALL DataciteDois with IDs #{from_id}-#{until_id} in batches of size #{shard_size}."
    count
  end

  def self.lookup_client_and_get_dois(client_id, options = {})
    # Search by propper ID
    client = ::Client.find_by(id: client_id, deleted_at: nil)
    if client.nil?
      # Search by symbol
      client = ::Client.find_by(symbol: client_id, deleted_at: nil)
      if client.nil?
        Rails.logger.error "Repository not found for client ID #{client_id}."
        exit
      end
    end

    # import DOIs for client
    Rails.logger.info "Grabbing DOIs for repository #{client.symbol}"

    client.dois
  end

  def self.import_by_client(client_id, options = {})
    # Abort if client_id is blank
    if client_id.blank?
      Rails.logger.error "Missing client ID."
      exit
    end
    # Get optional parameters
    import_index =
      if Rails.env.test?
        index_name
      elsif options[:index].present?
        options[:index]
      else
        active_index
      end

    batch_size = options[:batch_size] || 50

    # If skip_client is included in the options do not do a client lookup and just go to the Dois
    if options[:skip_client_lookup]
      client_dois = DataciteDoi.where(type: "DataciteDoi").where(datacentre: client_id)
    else
      client_dois = lookup_client_and_get_dois(client_id, options)
    end

    Rails.logger.info "Started import of #{client_dois.count} DOIs for client_id #{client_id} into the index '#{import_index}'"

    client_dois.select(:id).find_in_batches(batch_size: batch_size) do |dois|
      ids = dois.pluck(:id)
      DataciteDoiImportInBulkJob.perform_later(ids, index: import_index)
    end
  end

  def self.upload_to_elasticsearch(index, bulk_body)
    number_of_dois = bulk_body.length
    errors = 0
    response =
      DataciteDoi.__elasticsearch__.client.bulk index: index,
                                                type:
                                                  DataciteDoi.document_type,
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

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{
                          number_of_dois
                         } DataCite DOIs."
    elsif number_of_dois > 0
      Rails.logger.debug "[Elasticsearch] Imported #{number_of_dois} DataCite DOIs."
    end

    number_of_dois
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
    Aws::SQS::Errors::RequestEntityTooLarge,
    Faraday::ConnectionFailed,
    ActiveRecord::LockWaitTimeout => e

    Rails.logger.error "[Elasticsearch] Error #{e.class} with message #{e.message} importing DataCite DOIs."
  end


  # import DOIs in bulk
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
    selected_dois = DataciteDoi.where(id: ids, type: "DataciteDoi").includes(
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
    )
    selected_dois.find_in_batches(batch_size: batch_size) do |dois|
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
