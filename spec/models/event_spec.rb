require 'rails_helper'

describe Event, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "03f5743e-089e-4163-a406-f6529e81e422"
      events = Event.find_by_id(id)
      expect(events.size).to eq(1)
      expect(events.first).to eq(:id=>"03f5743e-089e-4163-a406-f6529e81e422", :subj_id=>"https://api.datacite.org/reports/21fd2e8e-5481-4bbd-b2ef-742d8b270a66", :obj_id=>"https://doi.org/10.7272/q6z60kzd", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>23164)
    end

    it "not found" do
      id = "https://doi.org/10.13039/xxx"
      event = Event.find_by_id(id)
      expect(event).to be_empty
    end
  end

  describe "query" do
    it "all" do
      query = nil
      events = Event.query(query)
      expect(events.size).to eq(100)
      expect(events.first).to eq(:id=>"c8bcd46c-3433-47ac-b8db-d039ce346d65", :subj_id=>"https://doi.org/10.5281/zenodo.595698", :obj_id=>"https://doi.org/10.13039/501100000780", :source_id=>"datacite-funder", :relation_type_id=>"is-funded-by", :total=>1)
    end

    it "limit" do
      query = nil
      events = Event.query(query, limit: 10)
      expect(events.size).to eq(10)
      expect(events.first).to eq(:id=>"c8bcd46c-3433-47ac-b8db-d039ce346d65", :subj_id=>"https://doi.org/10.5281/zenodo.595698", :obj_id=>"https://doi.org/10.13039/501100000780", :source_id=>"datacite-funder", :relation_type_id=>"is-funded-by", :total=>1)
    end

    it "source_id" do
      source_id = "datacite-usage"
      events = Event.query(nil, source_id: source_id)
      expect(events.size).to eq(100)
      expect(events.first).to eq(:id=>"308185f3-1607-478b-a25e-ed5671994db5", :subj_id=>"https://api.datacite.org/reports/fa2ad308-1b25-4394-9bc6-e0c7511e763d", :obj_id=>"https://doi.org/10.7272/q6g15xs4", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>4)
    end

    it "not found" do
      source_id = "xxx"
      events = Event.query(nil, source_id: source_id)
      expect(events).to be_empty
    end
  end
end