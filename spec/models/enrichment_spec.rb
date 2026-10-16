# frozen_string_literal: true

require "rails_helper"

describe Enrichment, type: :model, elasticsearch: false, prefix_pool_size: 1 do
  include ActiveJob::TestHelper

  describe "after_destroy_commit" do
    let(:doi) { create(:doi, type: "DataciteDoi") }
    let!(:enrichment) { create(:enrichment, doi_record: doi) }

    before do
      clear_enqueued_jobs
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "reindexes the DataciteDoi and deletes the EnrichedDoi when it is the last enrichment" do
      expect {
        enrichment.destroy
      }.to have_enqueued_job(IndexJobDoiRegistration).
        and have_enqueued_job(EnrichedDoiDeleteJob).with(doi.doi, { target_active_index: true })

      expect(doi.reload.has_enrichments).to be(false)
    end

    it "does nothing when other enrichments remain" do
      create(:enrichment, doi_record: doi)
      clear_enqueued_jobs

      expect {
        enrichment.destroy
      }.not_to have_enqueued_job(EnrichedDoiDeleteJob)

      expect(doi.reload.has_enrichments).to be(true)
    end

    it "does nothing when the associated record is not a DataciteDoi", prefix_pool_size: 2 do
      other_doi = create(:other_doi)
      other_enrichment = create(:enrichment, doi_record: other_doi)
      clear_enqueued_jobs

      expect {
        other_enrichment.destroy
      }.not_to have_enqueued_job(EnrichedDoiDeleteJob)
    end

    it "also deletes from the inactive index when index sync is enabled" do
      allow(DataciteDoi).to receive(:index_sync_enabled?).and_return(true)

      expect {
        enrichment.destroy
      }.to have_enqueued_job(EnrichedDoiDeleteJob).with(doi.doi, { target_active_index: true }).
        and have_enqueued_job(EnrichedDoiDeleteJob).with(doi.doi, { target_active_index: false })
    end
  end
end
