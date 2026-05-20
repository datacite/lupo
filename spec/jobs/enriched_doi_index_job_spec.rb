# frozen_string_literal: true

require "rails_helper"

describe EnrichedDoiIndexJob, type: :job do
  subject(:job) { described_class.new }

  let(:doi) { "10.0000/TEST.DOI" }
  let(:enrichments) { [] }
  let(:source_doi) do
    instance_double(
      Doi,
      enrichments: enrichments,
      attributes: { "doi" => doi },
      id: 123,
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
      doi: doi,
      invalid?: false,
      enrichment_uuids: enrichment_uuids,
    )
  end
  let(:enriched_doi) { instance_double(EnrichedDoi) }
  let(:es_proxy) { instance_double(Elasticsearch::Model::Proxy::InstanceMethodsProxy) }
  let(:enrichment_uuids) { %w[enrichment-a enrichment-b] }

  before do
    allow(Doi).to receive(:includes).with(:enrichments).and_return(Doi)
    allow(Doi).to receive(:find_by).with(doi: doi, agency: "datacite").and_return(source_doi)
    allow(source_doi).to receive(:only_validate=)
    allow(source_doi).to receive(:regenerate=)
    allow(source_doi).to receive(:skip_client_domains_validation=)
    allow(source_doi).to receive(:skip_schema_version_validation=)
    allow(source_doi).to receive(:schema_version=)
    allow(source_doi).to receive(:apply_enrichment)
    allow(EnrichedDoi).to receive(:new).with(source_doi.attributes).and_return(enriched_doi)
    allow(enriched_doi).to receive(:id=)
    allow(enriched_doi).to receive(:created_at=)
    allow(enriched_doi).to receive(:updated_at=)
    allow(enriched_doi).to receive(:indexed_enrichment_uuids=)
    allow(enriched_doi).to receive(:indexed_has_enrichments=)
    allow(enriched_doi).to receive(:__elasticsearch__).and_return(es_proxy)
    allow(es_proxy).to receive(:index_document).and_return({ "result" => "created" })
  end

  it "persists indexed enrichment metadata for Elasticsearch source" do
    expect(enriched_doi).to receive(:indexed_enrichment_uuids=).with(enrichment_uuids)
    expect(enriched_doi).to receive(:indexed_has_enrichments=).with(true)

    job.perform(doi)
  end

  context "when there are no enrichment uuids" do
    let(:enrichment_uuids) { [] }

    it "persists has_enrichments as false" do
      expect(enriched_doi).to receive(:indexed_enrichment_uuids=).with([])
      expect(enriched_doi).to receive(:indexed_has_enrichments=).with(false)

      job.perform(doi)
    end
  end
end
