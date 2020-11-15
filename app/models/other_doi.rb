class OtherDoi < Doi
  include Elasticsearch::Model

  # use different index for testing
  if Rails.env.test?
    index_name "dois-other-test"
  elsif ENV["ES_PREFIX"].present?
    index_name"dois-other-#{ENV["ES_PREFIX"]}"
  else
    index_name "dois-other"
  end

  def client_id=(value)
    write_attribute(:datacentre, 0)
  end

  def set_defaults
    self.is_active = (aasm_state == "findable") ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 1
    self.updated = Time.zone.now.utc.iso8601
    self.datacentre = 0
  end

  def self.import_by_ids(options={})
    # TODO remove query for type once STI is enabled
    from_id = (options[:from_id] || OtherDoi.where(type: "OtherDoi").minimum(:id)).to_i
    until_id = (options[:until_id] || OtherDoi.where(type: "OtherDoi").maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      OtherDoiImportByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued importing for other DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_id(options={})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index = if Rails.env.test?
              self.index_name
            elsif options[:index].present?
              options[:index]
            else
              self.inactive_index
            end
    errors = 0
    count = 0

    # TODO remove query for type once STI is enabled
    OtherDoi.where(type: "OtherDoi").where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |dois|
      response = OtherDoi.__elasticsearch__.client.bulk \
        index:   index,
        type:    OtherDoi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # try to handle errors
      errors_in_response = response['items'].select { |k, v| k.values.first['error'].present? }
      errors += errors_in_response.length
      errors_in_response.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
        doi_id = item.dig("index", "_id").to_i
        import_one(doi_id: doi_id) if doi_id > 0
      end

      count += dois.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} other DOIs with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} other DOIs with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    Rails.logger.info "[Elasticsearch] Error #{error.message} importing other DOIs with IDs #{id} - #{(id + 499)}."

    count = 0

    # TODO remove query for type once STI is enabled
    OtherDoi.where(type: "OtherDoi").where(id: id..(id + 499)).find_each do |doi|
      IndexJob.perform_later(doi)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} other DOIs with IDs #{id} - #{(id + 499)}."

    count
  end

# Transverses the index in batches and using the cursor pagination and executes a Job that matches the query and filter
  # Options:
  # +filter+:: paramaters to filter the index
  # +label+:: String to output in the logs printout
  # +query+:: ES query to filter the index
  # +job_name+:: Acive Job class name of the Job that would be executed on every matched results
  def self.loop_through_dois(options={})
    size = (options[:size] || 1000).to_i
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

    response = OtherDoi.query(query, filter.merge(page: { size: 1, cursor: [] }))
    message = "#{label} #{response.results.total} other dois with #{label}."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.results.length.positive?
        response = OtherDoi.query(query, filter.merge(page: { size: size, cursor: cursor }))
        break unless response.results.results.length.positive?

        Rails.logger.info "#{label} #{response.results.results.length} other dois starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "#{label} Cursor: #{cursor} "

        ids = response.results.results.map(&:uid)
        LoopThroughDoisJob.perform_later(ids, options)
      end
    end

    message
  end
end
