class IndexerJob < ActiveJob::Base
  queue_as :critical

  rescue_from ActiveJob::DeserializationError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :default
  end

  def perform(record, options={})
    operation = options[:operation] || "index"
    Rails.logger.debug [operation, "ID: #{record}"]

    es_client = Elasticsearch::Client.new host: ENV['ES_HOST']

    case operation
      when "index"
        es_client.index index: record.index, type: record.type, id: record.id, body: record.__elasticsearch__.as_indexed_json
      when "delete"
        es_client.delete index: record.index, type: record.type, id: record.id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
