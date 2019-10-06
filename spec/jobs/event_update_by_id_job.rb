require 'rails_helper'

describe EventUpdateByIdJob, type: :job do
  let(:event) { create(:event) }
  subject(:job) { EventUpdateByIdJob.perform_later(event.uuid) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(EventUpdateByIdJob)
      .on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
