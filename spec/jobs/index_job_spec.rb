require "rails_helper"

describe IndexJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { IndexJob.perform_later(doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(IndexJob).
      on_queue("test_lupo").at_least(1).times
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
