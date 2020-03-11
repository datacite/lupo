require "rails_helper"

describe UpdateStateJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { UpdateStateJob.perform_later(doi.doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(UpdateStateJob)
      .on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
