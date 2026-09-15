# frozen_string_literal: true

require "rails_helper"

describe EnrichedDoiDeleteJob, type: :job, elasticsearch: true, prefix_pool_size: 1 do
  let(:doi) { create(:doi, type: "DataciteDoi") }
  let!(:enrichment) { create(:enrichment, doi_record: doi) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect {
      described_class.perform_later(doi.doi, target_active_index: true)
    }.to have_enqueued_job(described_class).on_queue("test_enriched_doi_index_job")
  end

  it "deletes the EnrichedDoi document from OpenSearch" do
    EnrichedDoiIndexJob.perform_now(doi.doi)
    EnrichedDoi.__elasticsearch__.client.indices.refresh(index: EnrichedDoi.index_name)

    expect(
      EnrichedDoi.__elasticsearch__.client.exists?(index: EnrichedDoi.index_name, id: doi.id)
    ).to be(true)

    enrichment.destroy
    described_class.perform_now(doi.doi)

    EnrichedDoi.__elasticsearch__.client.indices.refresh(index: EnrichedDoi.index_name)
    expect(
      EnrichedDoi.__elasticsearch__.client.exists?(index: EnrichedDoi.index_name, id: doi.id)
    ).to be(false)
  end

  it "does not delete the EnrichedDoi when other enrichments remain" do
    create(:enrichment, doi_record: doi)
    EnrichedDoiIndexJob.perform_now(doi.doi)
    EnrichedDoi.__elasticsearch__.client.indices.refresh(index: EnrichedDoi.index_name)

    described_class.perform_now(doi.doi)

    EnrichedDoi.__elasticsearch__.client.indices.refresh(index: EnrichedDoi.index_name)
    expect(
      EnrichedDoi.__elasticsearch__.client.exists?(index: EnrichedDoi.index_name, id: doi.id)
    ).to be(true)
  end

  it "does not raise when the EnrichedDoi document is missing" do
    enrichment.destroy

    expect {
      described_class.perform_now(doi.doi)
    }.not_to raise_error
  end
end
