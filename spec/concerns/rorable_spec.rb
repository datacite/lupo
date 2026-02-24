# frozen_string_literal: true

require "rails_helper"

describe "Rorable", type: :model do
  let(:funder_to_ror_data) { { "100010552" => "https://ror.org/04ttjf776" } }
  let(:ror_hierarchy_data) do
    { "https://ror.org/00a0jsq62" => { "ancestors" => ["https://ror.org/04cw6st05"] } }
  end

  before do
    allow(RorReferenceStore).to receive(:funder_to_ror).and_return(funder_to_ror_data)
    allow(RorReferenceStore).to receive(:ror_hierarchy).and_return(ror_hierarchy_data)
  end

  describe "data is loaded" do
    it "loads Crossref Funder Id to ROR mapping" do
      expect(RorReferenceStore.funder_to_ror).to be_a(Hash)
      expect(RorReferenceStore.funder_to_ror).not_to be_empty
    end

    it "loads ROR hierarchy mapping" do
      expect(RorReferenceStore.ror_hierarchy).to be_a(Hash)
      expect(RorReferenceStore.ror_hierarchy).not_to be_empty
    end
  end

  describe "Crossref Funder ID to ROR mapping" do
    let(:doi) { create(:doi) }

    it "maps Crossref Funder ID without https://doi.org to ROR" do
      funder_id = "10.13039/100010552"
      ror_id = doi.get_ror_from_crossref_funder_id(funder_id)
      expect(ror_id).to eq("https://ror.org/04ttjf776")
    end

    it "does not map invalid Crossref Funder ID to ROR" do
      funder_id = "10.77777/100010552"
      ror_id = doi.get_ror_from_crossref_funder_id(funder_id)
      expect(ror_id).to eq(nil)
    end

    it "maps Crossref Funder ID with https://doi.org to ROR" do
      funder_id = "https://doi.org/10.13039/100010552"
      ror_id = doi.get_ror_from_crossref_funder_id(funder_id)
      expect(ror_id).to eq("https://ror.org/04ttjf776")
    end
  end

  describe "ROR to ancestor mapping" do
    let(:doi) { create(:doi) }

    it "maps ROR URL to ancestor" do
      ror_id = "https://ror.org/00a0jsq62"
      ancestors = doi.get_ror_parents(ror_id)
      expect(ancestors).to eq(["https://ror.org/04cw6st05"])
    end

    it "maps incomplete ROR URL to ancestor" do
      ror_id = "ror.org/00a0jsq62"
      ancestors = doi.get_ror_parents(ror_id)
      expect(ancestors).to eq(["https://ror.org/04cw6st05"])
    end

    it "maps ROR suffix to ancestor" do
      ror_id = "00a0jsq62"
      ancestors = doi.get_ror_parents(ror_id)
      expect(ancestors).to eq(["https://ror.org/04cw6st05"])
    end

    it "does not map invalid ROR to ancestor" do
      ror_id = "doi.org/00a0jsq62"
      ancestors = doi.get_ror_parents(ror_id)
      expect(ancestors).to eq([])
    end
  end
end
