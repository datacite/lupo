# frozen_string_literal: true

require "rails_helper"

describe EnrichedDoi, type: :model do
  subject(:enriched_doi) { described_class.new }

  it "prefers indexed enrichment uuids during serialization/indexing" do
    enriched_doi.indexed_enrichment_uuids = []
    expect(enriched_doi.enrichment_uuids).to eq([])

    enriched_doi.indexed_enrichment_uuids = %w[enrichment-1 enrichment-2]
    expect(enriched_doi.enrichment_uuids).to eq(%w[enrichment-1 enrichment-2])
  end

  it "prefers indexed has_enrichments flag during serialization/indexing" do
    enriched_doi.indexed_has_enrichments = false
    expect(enriched_doi.has_enrichments).to be(false)

    enriched_doi.indexed_has_enrichments = true
    expect(enriched_doi.has_enrichments).to be(true)
  end
end
