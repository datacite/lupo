require 'rails_helper'

describe DeleteJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { DeleteJob.perform_later(doi) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(DeleteJob)
      .on_queue("test_lupo")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end