# frozen_string_literal: true

require "rails_helper"

describe ResolvesElasticsearchIndex do
  let(:job_class) do
    Class.new(ApplicationJob) do
      include ResolvesElasticsearchIndex

      def call_resolve(model, options)
        resolve_options_index(model, options)
      end
    end
  end
  let(:job) { job_class.new }

  describe ".resolve_index_option" do
    it "resolves :active via the model" do
      allow(DataciteDoi).to receive(:active_index).and_return("dois_v1")
      expect(job_class.resolve_index_option(DataciteDoi, :active)).to eq("dois_v1")
    end

    it "resolves :inactive via the model" do
      allow(DataciteDoi).to receive(:inactive_index).and_return("dois_v2")
      expect(job_class.resolve_index_option(DataciteDoi, :inactive)).to eq("dois_v2")
    end

    it "passes through concrete index names" do
      expect(job_class.resolve_index_option(DataciteDoi, "dois_v1")).to eq("dois_v1")
    end
  end

  describe "#resolve_options_index" do
    it "replaces tokens with concrete names" do
      allow(DataciteDoi).to receive(:inactive_index).and_return("dois_v2")

      expect(job.call_resolve(DataciteDoi, { index: :inactive, batch_size: 10 })).to eq(
        { index: "dois_v2", batch_size: 10 },
      )
    end

    it "returns nil when a token cannot be resolved" do
      allow(DataciteDoi).to receive(:inactive_index).and_return(nil)

      expect(job.call_resolve(DataciteDoi, { index: :inactive })).to be_nil
    end

    it "leaves options without an index key unchanged" do
      expect(job.call_resolve(DataciteDoi, { batch_size: 25 })).to eq({ batch_size: 25 })
    end
  end
end

describe DataciteDoiImportInBulkJob, type: :job do
  let(:doi) { create(:doi, type: "DataciteDoi") }

  it "resolves :inactive before importing" do
    allow(DataciteDoi).to receive(:inactive_index).and_return("dois_v2")
    expect(DataciteDoi).to receive(:import_in_bulk).with([doi.id], hash_including(index: "dois_v2"))

    DataciteDoiImportInBulkJob.perform_now([doi.id], { index: :inactive })
  end

  it "skips import when :inactive cannot be resolved" do
    allow(DataciteDoi).to receive(:inactive_index).and_return(nil)
    expect(DataciteDoi).not_to receive(:import_in_bulk)

    DataciteDoiImportInBulkJob.perform_now([doi.id], { index: :inactive })
  end

  it "passes through a concrete index name" do
    expect(DataciteDoi).to receive(:import_in_bulk).with([doi.id], hash_including(index: "custom-index"))

    DataciteDoiImportInBulkJob.perform_now([doi.id], { index: "custom-index" })
  end
end

describe OtherDoiImportInBulkJob, type: :job do
  let(:doi) { create(:other_doi, agency: "crossref") }

  it "resolves :active before importing" do
    allow(OtherDoi).to receive(:active_index).and_return("dois-other_v1")
    expect(OtherDoi).to receive(:import_in_bulk).with([doi.id], hash_including(index: "dois-other_v1"))

    OtherDoiImportInBulkJob.perform_now([doi.id], { index: :active })
  end
end
