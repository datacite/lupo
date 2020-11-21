require "rails_helper"

describe EventImportByIdJob, type: :job, vcr: true do
  let(:event) { create(:event) }
  subject(:job) { EventImportByIdJob.perform_later(event.id) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(EventImportByIdJob).
      on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
