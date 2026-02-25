# frozen_string_literal: true

require "rails_helper"

describe "Rorable", type: :model do
  before do
    allow(RorReferenceStore).to receive(:funder_to_ror).with("100010552").and_return("https://ror.org/04ttjf776")
    allow(RorReferenceStore).to receive(:funder_to_ror).with("10.77777/100010552").and_return(nil)
    allow(RorReferenceStore).to receive(:ror_hierarchy).with("https://ror.org/00a0jsq62").and_return(
      { "ancestors" => ["https://ror.org/04cw6st05"] }
    )
    allow(RorReferenceStore).to receive(:ror_hierarchy).with("https://ror.org/doi.org/00a0jsq62").and_return(nil)
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
      expect(ror_id).to be_nil
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
