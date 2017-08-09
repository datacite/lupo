class Indexer
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: false

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Client.new host: 'elasticsearch:9200', logger: Logger

  def perform(operation, record)
    logger.debug [operation, "ID: #{record.id}"]

    case operation.to_s
      when /index/
        Client.index  index: record.index, type: record.type, id: record.id, body: record.__elasticsearch__.as_indexed_json
      when /delete/
        Client.delete index: record.index, type: record.type, id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
