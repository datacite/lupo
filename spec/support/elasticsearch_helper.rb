## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Client, Provider, DataciteDoi, Doi, Event, Activity, Prefix, ClientPrefix, ProviderPrefix]

RSpec.configure do |config|
  config.around :example, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.delete index: "#{model.index_name}_v1" if Elasticsearch::Model.client.indices.exists? index: "#{model.index_name}_v1"
      Elasticsearch::Model.client.indices.delete index: "#{model.index_name}_v2" if Elasticsearch::Model.client.indices.exists? index: "#{model.index_name}_v2"

      model.__elasticsearch__.create_index! force: true
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.delete index: model.index_name if Elasticsearch::Model.client.indices.exists? index: model.index_name
    end
  end
end
