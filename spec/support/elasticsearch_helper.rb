## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [Client, Provider, Doi, Prefix]

RSpec.configure do |config|
  config.around :each, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.create index: model.index_name rescue nil
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      Elasticsearch::Model.client.indices.delete index: model.index_name
    end
  end
end
