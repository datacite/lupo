require 'rails_helper'

describe TransferJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { TransferJob.perform_later(doi.doi) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(TransferJob)
      .on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end