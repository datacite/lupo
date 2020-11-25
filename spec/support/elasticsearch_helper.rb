# frozen_string_literal: true

## https://github.com/elastic/elasticsearch-ruby/issues/462
SEARCHABLE_MODELS = [
  Client,
  Provider,
  DataciteDoi,
  OtherDoi,
  Doi,
  Event,
  Activity,
  Prefix,
  ClientPrefix,
  ProviderPrefix,
].freeze

RSpec.configure do |config|
  config.around :example, elasticsearch: true do |example|
    SEARCHABLE_MODELS.each do |model|
      if model.name == "DataciteDoi" || model.name == "OtherDoi"
        model.create_template
      end

      if Elasticsearch::Model.client.indices.exists? index:
                                                     "#{model.index_name}_v1"
        Elasticsearch::Model.client.indices.delete index:
                                                     "#{model.index_name}_v1"
      end
      if Elasticsearch::Model.client.indices.exists? index:
                                                     "#{model.index_name}_v2"
        Elasticsearch::Model.client.indices.delete index:
                                                     "#{model.index_name}_v2"
      end

      model.__elasticsearch__.create_index! force: true
    end

    example.run

    SEARCHABLE_MODELS.each do |model|
      if Elasticsearch::Model.client.indices.exists? index: model.index_name
        Elasticsearch::Model.client.indices.delete index: model.index_name
      end
    end
  end
end
