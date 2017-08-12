class ElasticsearchBulkIndexWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: 'low'

  def client
    @client = Elasticsearch::Client.new host: env['ES_HOST']
  end

  def perform(model, starting_index)
    klass = model.capitalize.constantize
    batch_for_bulk = []
    klass.where(id: starting_index..(starting_index+999)).each do |record|
      batch_for_bulk.push({ index: { _id: record.id, data: record.as_indexed_json } }) unless record.try(:archived)
    end
    klass.__elasticsearch__.client.bulk(
      index: "#{model.pluralize}",
      type: model,
      body: batch_for_bulk
    )
  end
end
