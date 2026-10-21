# frozen_string_literal: true

SEARCHABLE_MODELS = [
  Client,
  Provider,
  DataciteDoi,
  OtherDoi,
  Doi,
  EnrichedDoi,
  Event,
  Activity,
  Prefix,
  ClientPrefix,
  ProviderPrefix,
  Contact,
  ReferenceRepository,
].freeze

# Doi and DataciteDoi share an index, so dedupe.
SEARCHABLE_INDEX_NAMES = SEARCHABLE_MODELS.map { |esc| esc.index_name.to_s }.uniq.freeze

def create_missing_search_indexes
  SEARCHABLE_MODELS.each do |esc|
    if esc.name == "DataciteDoi" || esc.name == "OtherDoi"
      esc.create_template
    end

    unless Elasticsearch::Model.client.indices.exists?(index: esc.index_name.to_s)
      esc.__elasticsearch__.client.indices.create(
        index: esc.index_name,
        body: { settings: esc.settings.to_hash, mappings: esc.mappings.to_hash }
      )
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { create_missing_search_indexes }

  # Give each tagged example empty indexes (plus whatever is already in the DB)
  # without dropping and recreating every index, which is slow.
  config.before(:each, elasticsearch: true) do
    client = Elasticsearch::Model.client

    # A spec may have dropped an index.
    create_missing_search_indexes unless client.indices.exists?(index: SEARCHABLE_INDEX_NAMES)

    # delete_by_query only sees refreshed documents, so refresh first to also
    # catch documents indexed (e.g. by after_commit callbacks) in earlier examples.
    client.indices.refresh(index: SEARCHABLE_INDEX_NAMES)
    client.delete_by_query(
      index: SEARCHABLE_INDEX_NAMES,
      body: { query: { match_all: {} } },
      conflicts: "proceed",
      refresh: true
    )

    # Re-index records that outlive the example transaction (e.g. before :all data).
    SEARCHABLE_MODELS.each do |esc|
      esc.import(refresh: true) if esc.exists?
    end
  end
end
