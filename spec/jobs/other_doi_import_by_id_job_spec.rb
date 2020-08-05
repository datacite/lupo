require 'rails_helper'

describe OtherDoiImportByIdJob, type: :job do
  let(:doi) { create(:doi, type: "DataciteDoi") }
  subject(:job) { OtherDoiImportByIdJob.perform_later(doi.id) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(OtherDoiImportByIdJob)
      .on_queue("test_lupo_import_other_doi")
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
