require 'rails_helper'

describe Funder, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://doi.org/10.13039/100011326"
      funders = Funder.find_by_id(id)
      expect(funders[:data].size).to eq(1)
      expect(funders[:data].first).to eq(id: "https://doi.org/10.13039/100011326", name: "London School of Economics and Political Science", alternate_name: ["London School of Economics & Political Science", "LSE"], date_modified: "2019-04-18T00:00:00Z")
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
      expect(funders[:data].first).to eq(id: "https://doi.org/10.13039/100002569", name: "American Association of Endodontists Foundation", alternate_name: ["AAE Foundation for Endodontics", "AAE Foundation", "Foundation for Endodontics", "AAEF"], country: "United States", date_modified: "2019-04-18T00:00:00Z")
    end

    it "limit" do
      query = nil
      funders = Funder.query(query, limit: 10)
      expect(funders.dig(:meta, "total")).to eq(19662)
      expect(funders[:data].size).to eq(10)
      expect(funders[:data].first).to eq(id: "https://doi.org/10.13039/100002569", name: "American Association of Endodontists Foundation", alternate_name: ["AAE Foundation for Endodontics", "AAE Foundation", "Foundation for Endodontics", "AAEF"], country: "United States", date_modified: "2019-04-18T00:00:00Z")
    end

    it "found" do
      query = "dfg"
      funders = Funder.query(query)
      expect(funders.dig(:meta, "total")).to eq(3)
      expect(funders[:data].size).to eq(3)
      expect(funders[:data].first).to eq(id: "https://doi.org/10.13039/501100001659", name: "Deutsche Forschungsgemeinschaft", alternate_name: ["DFG", "German Research Association", "German Research Foundation"], date_modified: "2019-04-18T00:00:00Z")
    end

    it "not found" do
      query = "xxx"
      funders = Funder.query(query)
      expect(funders[:data]).to be_empty
      expect(funders[:errors]).to be_nil
    end
  end
end