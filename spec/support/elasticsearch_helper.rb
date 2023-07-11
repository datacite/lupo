# frozen_string_literal: true

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
  Contact,
  ReferenceRepository,
  DataDump,
].freeze

RSpec.configure do |config|
  config.before :all do
    SEARCHABLE_MODELS.each do |esc|
      if esc.name == "DataciteDoi" || esc.name == "OtherDoi"
        esc.create_template
      end

      if Elasticsearch::Model.client.indices.exists?(index: esc.index_name)
        esc.__elasticsearch__.client.indices.delete index: esc.index_name
      end

      esc.__elasticsearch__.client.indices.create(
        index: esc.index_name,
        body: { settings: esc.settings.to_hash, mappings: esc.mappings.to_hash }
      )
    end
  end

  config.after :all do
    SEARCHABLE_MODELS.each do |esc|
      if Elasticsearch::Model.client.indices.exists?(index: esc.index_name)
        esc.__elasticsearch__.client.indices.delete index: esc.index_name
      end
    end
  end

  config.before(:each, elasticsearch: true) do
    SEARCHABLE_MODELS.each { |esc| esc.import(refresh: true, force: true) }
  end
end
