# frozen_string_literal: true

require "rails_helper"

describe ActivityImportByIdJob, type: :job do
  let(:activity) { create(:activity) }
  subject(:job) { ActivityImportByIdJob.perform_later(activity.id) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(ActivityImportByIdJob).on_queue(
      "test_lupo_background",
    )
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
