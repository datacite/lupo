require 'rails_helper'

describe IndexJob, type: :job do
  let(:client) { create(:client) }
  subject(:job) { IndexJob.perform_later(client) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(IndexJob)
      .on_queue("test_elastic")
  end
end
