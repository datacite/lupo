# frozen_string_literal: true

require "rails_helper"

describe DataciteDoiImportInBulkJob, type: :job do
  let(:doi) { create(:doi, type: "DataciteDoi") }
  subject(:job) { DataciteDoiImportInBulkJob.perform_later([{ "id" => doi.id, "as_indexed_json" => doi.as_indexed_json }]) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(DataciteDoiImportInBulkJob).on_queue(
      "test_lupo_import",
    )
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
