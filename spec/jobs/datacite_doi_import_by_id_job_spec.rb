require 'rails_helper'

describe DataciteDoiImportByIdJob, type: :job do
  let(:doi) { create(:doi, type: "DataciteDoi") }
  subject(:job) { DataciteDoiImportByIdJob.perform_later(doi.id) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(DataciteDoiImportByIdJob)
      .on_queue("test_lupo_import")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
