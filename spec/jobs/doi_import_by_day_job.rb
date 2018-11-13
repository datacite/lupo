require 'rails_helper'

describe DoiImportByDayJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { DoiImportByDayJob.perform_later(Time.zone.now.strftime("%F")) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(DoiImportByDayJob)
      .on_queue("test_lupo_background")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end