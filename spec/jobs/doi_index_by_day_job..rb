require 'rails_helper'

describe DoiIndexByDayJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { DoiIndexByDayJob.perform_later(Time.zone.now.strftime("%F")) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(DoiIndexByDayJob)
      .on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end