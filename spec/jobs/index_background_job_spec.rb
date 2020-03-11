require "rails_helper"

describe IndexBackgroundJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { IndexBackgroundJob.perform_later(doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(IndexBackgroundJob)
      .on_queue("test_lupo_background").at_least(1).times
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
