class IndexerJob < ActiveJob::Base
  queue_as :critical

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :default
  end

  def perform(record, options={})
    operation = options[:operation] || "index"
    Rails.logger.debug [operation, "ID: #{record}"]

    client = Elasticsearch::Client.new

    case operation
      when "index"
        client.index index: record.index, type: record.type, id: record.id, body: record.__elasticsearch__.as_indexed_json
      when "delete"
        client.delete index: record.index, type: record.type, id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
