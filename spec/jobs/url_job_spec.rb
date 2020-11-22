# frozen_string_literal: true

require "rails_helper"

describe UrlJob, type: :job do
  let(:doi) { create(:doi) }
  subject(:job) { UrlJob.perform_later(doi.doi) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(UrlJob).on_queue("test_lupo")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
