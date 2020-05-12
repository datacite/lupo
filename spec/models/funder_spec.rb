require 'rails_helper'

describe Funder, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://doi.org/10.13039/501100006568"
      funder = Funder.find_by_id(id)
      expect(funder[:data].size).to eq(1)
      funder = funder[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/501100006568")
      expect(funder.name).to eq("Toagosei")
      expect(funder.alternate_name).to eq(["Toagosei Co., Ltd.", "Toagosei Chemical Industry Company Limited", "Toagosei Company Limited"])
      expect(funder.country).to eq("code"=>"JP", "name"=>"Japan")
    end

    it "not found" do
      id = "https://doi.org/10.13039/xxxxx"
      funder = Funder.find_by_id(id)
      expect(funder[:data]).to be_nil
      expect(funder[:errors]).to eq([{"status"=>404, "title"=>"Not found."}])
    end

    it "not a doi" do
      id = "xxxxx"
      funder = Funder.find_by_id(id)
      expect(funder[:data]).to be_nil
      expect(funder[:errors]).to eq([{"status"=>422, "title"=>"Not a valid DOI."}])
    end
  end

  describe "query" do
    it "found all" do
      query = nil
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(22357)
      expect(funders.dig(:data).size).to eq(25)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/501100010742")
      expect(funder.name).to eq("Sandvik Coromant")
      expect(funder.alternate_name).to be_empty
      expect(funder.country).to eq("code"=>"SE", "name"=>"Sweden")
    end

    it "found all paginate" do
      query = nil
      funders = Funder.query(query, offset: 1)
      expect(funders.dig(:meta, "total")).to eq(22357)
      expect(funders.dig(:data).size).to eq(25)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/501100006568")
      expect(funder.name).to eq("Toagosei")
      expect(funder.alternate_name).to eq(["Toagosei Co., Ltd.", "Toagosei Chemical Industry Company Limited", "Toagosei Company Limited"])
      expect(funder.country).to eq("code"=>"JP", "name"=>"Japan")
    end

    it "found dfg" do
      query = "dfg"
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(3)
      expect(funders.dig(:data).size).to eq(3)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/100004875")
      expect(funder.name).to eq("Massachusetts Department of Fish and Game")
      expect(funder.alternate_name).to eq(["Department of Fish and Game", "DFG", "MassDFG"])
      expect(funder.country).to eq("code"=>"US", "name"=>"United States")
    end

    it "not found" do
      query = "xxxxx"
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(0)
      expect(funders.dig(:data).size).to eq(0)
    end
  end
end
