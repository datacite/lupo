require 'rails_helper'

describe UrlJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { UrlJob.perform_later(doi) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(UrlJob)
      .on_queue("test_lupo")
  end
end
