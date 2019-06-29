## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Client, Provider, Doi, Event, Researcher]

RSpec.configure do |config|
  config.around :all, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      if Elasticsearch::Model.client.indices.exists? index: model.index_name
        model.__elasticsearch__.create_index! force: true
      else
        model.__elasticsearch__.create_index!
      end
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.delete index: model.index_name
    end
  end
end
