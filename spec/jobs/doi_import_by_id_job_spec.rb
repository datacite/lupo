# frozen_string_literal: true

require "rails_helper"

describe DoiImportByIdJob, type: :job do
  let(:doi) { create(:doi, type: "DataciteDoi") }
  subject(:job) { DoiImportByIdJob.perform_later(doi.id) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(DoiImportByIdJob).on_queue(
      "test_lupo_import",
    )
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
