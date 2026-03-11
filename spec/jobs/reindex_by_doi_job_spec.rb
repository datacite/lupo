# frozen_string_literal: true

require "rails_helper"

describe ReindexByDoiJob, type: :job do
  let(:datacite_doi) { create(:doi, agency: "datacite") }
  let(:other_doi) { create(:doi, agency: "crossref") }
  subject(:job) { ReindexByDoiJob.perform_later(nil, datacite_doi.doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(ReindexByDoiJob).on_queue(
      "test_lupo_background",
    )
  end

  it "queues DataciteDoiImportInBulkJob for agency 'datacite'" do
    ReindexByDoiJob.new.perform(nil, datacite_doi.doi)

    enqueued_job = enqueued_jobs.find { |j| j[:job] == DataciteDoiImportInBulkJob }
    expect(enqueued_job).to be_present
    expect(enqueued_job[:args].first).to eq([datacite_doi.id])
  end

  it "queues OtherDoiImportInBulkJob for agency 'crossref'" do
    ReindexByDoiJob.new.perform(nil, other_doi.doi)

    enqueued_job = enqueued_jobs.find { |j| j[:job] == OtherDoiImportInBulkJob }
    expect(enqueued_job).to be_present
    expect(enqueued_job[:args].first).to eq([other_doi.id])
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
