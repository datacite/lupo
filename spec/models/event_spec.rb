require 'rails_helper'

describe Event, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "03f5743e-089e-4163-a406-f6529e81e422"
      response = Event.find_by_id(id)
      expect(response[:data].size).to eq(1)
      expect(response[:data].first).to eq(:id=>"03f5743e-089e-4163-a406-f6529e81e422", :subj_id=>"https://api.datacite.org/reports/21fd2e8e-5481-4bbd-b2ef-742d8b270a66", :obj_id=>"https://doi.org/10.7272/q6z60kzd", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>23164)
    end

    it "not found" do
      id = "xxx"
      response = Event.find_by_id(id)
      expect(response[:data]).to be_empty
      expect(response[:errors]).to eq([{"status"=>404, "title"=>"Not found"}])
    end
  end

  describe "query" do
    it "all" do
      query = nil
      response = Event.query(query)
      expect(response[:data].size).to eq(100)
      expect(response[:data].first).to eq(:id=>"c8bcd46c-3433-47ac-b8db-d039ce346d65", :subj_id=>"https://doi.org/10.5281/zenodo.595698", :obj_id=>"https://doi.org/10.13039/501100000780", :source_id=>"datacite-funder", :relation_type_id=>"is-funded-by", :total=>1)
    end

    it "limit" do
      query = nil
      response = Event.query(query, limit: 10)
      expect(response[:data].size).to eq(10)
      expect(response[:data].first).to eq(:id=>"c8bcd46c-3433-47ac-b8db-d039ce346d65", :subj_id=>"https://doi.org/10.5281/zenodo.595698", :obj_id=>"https://doi.org/10.13039/501100000780", :source_id=>"datacite-funder", :relation_type_id=>"is-funded-by", :total=>1)
    end

    it "source_id" do
      source_id = "datacite-usage"
      response = Event.query(nil, source_id: source_id)
      expect(response[:data].size).to eq(100)
      expect(response[:data].first).to eq(:id=>"308185f3-1607-478b-a25e-ed5671994db5", :subj_id=>"https://api.datacite.org/reports/fa2ad308-1b25-4394-9bc6-e0c7511e763d", :obj_id=>"https://doi.org/10.7272/q6g15xs4", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>4)
    end

    it "not found" do
      source_id = "xxx"
      response = Event.query(nil, source_id: source_id)
      expect(response[:data]).to be_empty
      expect(response[:meta]).to eq("page"=>1, "total"=>0, "totalPages"=>0)
    end
  end
end