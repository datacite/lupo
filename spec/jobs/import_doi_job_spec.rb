# frozen_string_literal: true

require "rails_helper"

describe ImportDoiJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { ImportDoiJob.perform_later(doi.doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(ImportDoiJob).on_queue(
      "test_lupo_background",
    ).
      at_least(1).
      times
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
