require 'rails_helper'

describe Funder, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://doi.org/10.13039/100011326"
      funders = Funder.find_by_id(id)
      expect(funders[:data].size).to eq(1)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/100011326")
      expect(funder.name).to eq("London School of Economics and Political Science")
      expect(funder.alternate_name).to eq(["London School of Economics & Political Science", "LSE"])
    end

    it "not found" do
      id = "https://doi.org/10.13039/xxx"
      funder = Funder.find_by_id(id)
      expect(funder).to be_empty
    end
  end

  describe "query" do
    it "all" do
      query = nil
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(19662)
      expect(funders[:data].size).to eq(100)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/100002569")
      expect(funder.name).to eq("American Association of Endodontists Foundation")
      expect(funder.alternate_name).to eq(["AAE Foundation for Endodontics", "AAE Foundation", "Foundation for Endodontics", "AAEF"])
    end

    it "limit" do
      query = nil
      funders = Funder.query(query, limit: 10)
      expect(funders.dig(:meta, "total")).to eq(19662)
      expect(funders[:data].size).to eq(10)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/100002569")
      expect(funder.name).to eq("American Association of Endodontists Foundation")
      expect(funder.alternate_name).to eq(["AAE Foundation for Endodontics", "AAE Foundation", "Foundation for Endodontics", "AAEF"])
    end

    it "found" do
      query = "dfg"
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(3)
      expect(funders[:data].size).to eq(3)
      funder = funders[:data].first
      expect(funder.id).to eq("https://doi.org/10.13039/501100001659")
      expect(funder.name).to eq("Deutsche Forschungsgemeinschaft")
      expect(funder.alternate_name).to eq(["DFG", "German Research Association", "German Research Foundation"])
    end

    it "not found" do
      query = "xxx"
      funders = Funder.query(query)
      expect(funders[:data]).to be_empty
      expect(funders[:errors]).to be_nil
    end
  end
end