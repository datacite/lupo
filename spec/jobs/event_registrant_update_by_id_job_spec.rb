# frozen_string_literal: true

require "rails_helper"

describe EventRegistrantUpdateByIdJob, type: :job, vcr: true do
  let(:event) { create(:event) }
  subject(:job) { EventRegistrantUpdateByIdJob.perform_later(event.uuid) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(EventRegistrantUpdateByIdJob).on_queue(
      "test_lupo_background",
    )
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
