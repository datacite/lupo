require "rails_helper"

describe UpdateDoiJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { UpdateDoiJob.perform_later(doi.doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(UpdateDoiJob)
      .on_queue("test_lupo_background").at_least(1).times
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
