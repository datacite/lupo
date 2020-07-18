class CrossrefDoi < Doi
  # use different index for testing
  if Rails.env.test?
    index_name "dois-crossref-test"
  elsif ENV["ES_PREFIX"].present?
    index_name"dois-crossref-#{ENV["ES_PREFIX"]}"
  else
    index_name "dois-crossref"
  end

  def self.import_by_ids(options={})
    puts options
    from_id = (options[:from_id] || CrossrefDoi.minimum(:id)).to_i
    until_id = (options[:until_id] || CrossrefDoi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      CrossrefDoiImportByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued importing for Crossref DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_id(options={})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index = if Rails.env.test?
              "dois-crossref-test"
            elsif options[:index].present?
              options[:index]
            else
              self.inactive_index
            end
    errors = 0
    count = 0

    CrossrefDoi.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |dois|
      response = CrossrefDoi.__elasticsearch__.client.bulk \
        index:   index,
        type:    CrossrefDoi.document_type,
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
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} Crossref DOIs with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} Crossref DOIs with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    Rails.logger.info "[Elasticsearch] Error #{error.message} importing Crossref DOIs with IDs #{id} - #{(id + 499)}."

    count = 0

    CrossrefDoi.where(id: id..(id + 499)).find_each do |doi|
      IndexJob.perform_later(doi)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} Crossref DOIs with IDs #{id} - #{(id + 499)}."

    count
  end
end
