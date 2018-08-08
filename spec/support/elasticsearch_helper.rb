## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Client, Provider, Doi, Event]

RSpec.configure do |config|
  config.around :each, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      if Elasticsearch::Model.client.indices.exists? index: model.index_name
        model.__elasticsearch__.create_index! force: true
      else
        model.__elasticsearch__.create_index!
      end
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      if Elasticsearch::Model.client.indices.exists? index: model.index_name
        Elasticsearch::Model.client.indices.delete index: model.index_name
      end
    end
  end
end
