# frozen_string_literal: true

require "rails_helper"

describe IndexJobDoiRegistration, type: :job do
  let(:doi) { create(:doi, minted: nil) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    doi
    expect { IndexJobDoiRegistration.perform_later(doi) }.
      to have_enqueued_job(IndexJobDoiRegistration).on_queue("test_lupo_doi_registration")
  end

  it "reloads the DOI before indexing so registered is present" do
    minted_at = Time.zone.parse("2026-03-29T21:48:59Z")
    doi.update_columns(minted: minted_at)
    doi.minted = nil

    elasticsearch = instance_double("ElasticsearchIndexer")
    allow(doi).to receive(:__elasticsearch__).and_return(elasticsearch)
    expect(elasticsearch).to receive(:index_document) do
      expect(doi.minted).to be_present
      { "result" => "updated" }
    end

    IndexJobDoiRegistration.perform_now(doi)
  end
end
