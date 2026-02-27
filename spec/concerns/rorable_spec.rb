# frozen_string_literal: true

require "rails_helper"

describe "Rorable", type: :model do
  describe "data is loaded" do
    it "loads Crossref Funder Id to ROR mapping" do
      expect(FUNDER_TO_ROR).to be_a(Hash)
      expect(FUNDER_TO_ROR).not_to be_empty
    end

    it "loads ROR hierarchy mapping" do
      expect(ROR_HIERARCHY).to be_a(Hash)
      expect(ROR_HIERARCHY).not_to be_empty
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

    let(:ror_url) { "https://ror.org/00k4n6c32" }
    let(:ror_incomplete_url) { "ror.org/00k4n6c32" }
    let(:ror_suffix) { "00k4n6c32" }

    let(:uppercase_fixture_ror_url) { "https://ror.org/00a0jsq62" }

    it "loads ROR to countries mapping" do
      expect(ROR_TO_COUNTRIES).to be_a(Hash)
      expect(ROR_TO_COUNTRIES).not_to be_empty
    end

    it "maps ROR URL to country codes" do
      expected = Array.wrap(ROR_TO_COUNTRIES[ror_url]).map(&:upcase).uniq
      expect(doi.get_countries_from_ror(ror_url)).to eq(expected)
    end

    it "maps incomplete ROR URL to country codes" do
      expected = Array.wrap(ROR_TO_COUNTRIES[ror_url]).map(&:upcase).uniq
      expect(doi.get_countries_from_ror(ror_incomplete_url)).to eq(expected)
    end

    it "maps ROR suffix to country codes" do
      expected = Array.wrap(ROR_TO_COUNTRIES[ror_url]).map(&:upcase).uniq
      expect(doi.get_countries_from_ror(ror_suffix)).to eq(expected)
    end

    it "returns empty array for invalid ROR" do
      ror_id = "doi.org/00k4n6c32"
      expect(doi.get_countries_from_ror(ror_id)).to eq([])
    end

    it "returns empty array for ROR not in mapping" do
      ror_id = "https://ror.org/nonexistent"
      expect(doi.get_countries_from_ror(ror_id)).to eq([])
    end

    it "normalizes country codes to uppercase" do
      # Prove normalization by comparing to an upcased expected value from the mapping.
      expected = Array.wrap(ROR_TO_COUNTRIES[uppercase_fixture_ror_url]).map(&:upcase).uniq
      expect(doi.get_countries_from_ror(uppercase_fixture_ror_url)).to eq(expected)
    end
  end
end
