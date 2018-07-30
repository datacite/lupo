require 'rails_helper'

describe HandleJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { HandleJob.perform_later(doi.doi) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(HandleJob)
      .on_queue("test_lupo")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
