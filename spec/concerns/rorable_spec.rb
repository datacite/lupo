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
    allow(RorReferenceStore).to receive(:ror_to_countries).with("https://ror.org/00k4n6c32").and_return(["US"])
    allow(RorReferenceStore).to receive(:ror_to_countries).with("https://ror.org/00a0jsq62").and_return(["us"])
    allow(RorReferenceStore).to receive(:ror_to_countries).with("https://ror.org/nonexistent").and_return(nil)
    allow(RorReferenceStore).to receive(:ror_to_countries).with("https://ror.org/doi.org/00k4n6c32").and_return(nil)
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

  describe "ROR to country mapping" do
    let(:doi) { create(:doi) }

    it "maps ROR URL to country codes" do
      expect(doi.get_countries_from_ror("https://ror.org/00k4n6c32")).to eq(["US"])
    end

    it "maps incomplete ROR URL to country codes" do
      expect(doi.get_countries_from_ror("ror.org/00k4n6c32")).to eq(["US"])
    end

    it "maps ROR suffix to country codes" do
      expect(doi.get_countries_from_ror("00k4n6c32")).to eq(["US"])
    end

    it "returns empty array for invalid ROR" do
      expect(doi.get_countries_from_ror("doi.org/00k4n6c32")).to eq([])
    end

    it "returns empty array for ROR not in mapping" do
      expect(doi.get_countries_from_ror("https://ror.org/nonexistent")).to eq([])
    end

    it "normalizes country codes to uppercase" do
      # Store returns lowercase "us" — method must upcase it
      expect(doi.get_countries_from_ror("https://ror.org/00a0jsq62")).to eq(["US"])
    end
  end
end
