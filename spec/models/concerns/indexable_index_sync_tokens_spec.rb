# frozen_string_literal: true

require "rails_helper"

describe "Indexable index sync tokens" do
  let(:indices) { Elasticsearch::Model.client.indices }

  before do
    Rails.cache.delete(SharedContainerSettings::INDEX_SYNC_KEY)
    allow(SharedContainerSettings).to receive(:index_sync_enabled?).and_return(true)
  end

  after do
    Rails.cache.delete(SharedContainerSettings::INDEX_SYNC_KEY)
  end

  it "enqueues DataciteDoiImportInBulkJob with :inactive and does not call get_alias on create/update" do
    allow(indices).to receive(:get_alias).and_call_original
    expect(DataciteDoiImportInBulkJob).to receive(:perform_later).with(
      kind_of(Array),
      hash_including(index: :inactive),
    )
    expect(IndexJobDoiRegistration).to receive(:perform_later)

    create(:doi, type: "DataciteDoi")

    expect(indices).not_to have_received(:get_alias)
  end

  it "enqueues OtherDoi dual-write with :active and :inactive without calling get_alias" do
    allow(indices).to receive(:get_alias).and_call_original
    expect(OtherDoiImportInBulkJob).to receive(:perform_later).with(
      kind_of(Array),
      hash_including(index: :active),
    ).ordered
    expect(OtherDoiImportInBulkJob).to receive(:perform_later).with(
      kind_of(Array),
      hash_including(index: :inactive),
    ).ordered

    create(:other_doi, agency: "crossref")

    expect(indices).not_to have_received(:get_alias)
  end
end
