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
      expect(response.dig(:meta, "total")).to eq(9165580)
      expect(response[:data].size).to eq(10)
      expect(response[:data].first).to eq(:id=>"c8bcd46c-3433-47ac-b8db-d039ce346d65", :subj_id=>"https://doi.org/10.5281/zenodo.595698", :obj_id=>"https://doi.org/10.13039/501100000780", :source_id=>"datacite-funder", :relation_type_id=>"is-funded-by", :total=>1)
    end

    it "source_id" do
      source_id = "datacite-usage"
      response = Event.query(nil, source_id: source_id)
      expect(response.dig(:meta, "total")).to eq(16672)
      expect(response[:data].size).to eq(100)
      expect(response[:data].first).to eq(:id=>"308185f3-1607-478b-a25e-ed5671994db5", :subj_id=>"https://api.datacite.org/reports/fa2ad308-1b25-4394-9bc6-e0c7511e763d", :obj_id=>"https://doi.org/10.7272/q6g15xs4", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>4)
    end

    it "citation_type" do
      citation_type = "Dataset-Funder"
      response = Event.query(nil, citation_type: citation_type)
      expect(response.dig(:meta, "total")).to eq(27246)
      expect(response[:data].size).to eq(100)
      expect(response[:data].first).to eq(:id => "28fa7d4f-60e0-4db8-8365-b19b1b9904e9",
        :obj_id => "https://doi.org/10.13039/100000050",
        :relation_type_id => "is-funded-by",
        :source_id => "datacite-funder",
        :subj_id => "https://doi.org/10.23725/e9sa-1y49",
        :total => 1)
    end

    it "doi" do
      doi = "https://doi.org/10.7272/q6z60kzd"
      response = Event.query(nil, doi: doi)
      expect(response[:data].size).to eq(22)
      expect(response[:data].first).to eq(:id=>"758199db-95c9-4216-ae7a-70b9d00425d4", :subj_id=>"https://api.datacite.org/reports/08761bb6-f8d9-4d01-8012-fd21042fd71d", :obj_id=>"https://doi.org/10.7272/q6z60kzd", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>58)
      expect(response.dig(:meta, "relationTypes", 0, "yearMonths")).to eq([{"id"=>"2018-04", "title"=>"April 2018", "sum"=>23171.0},
        {"id"=>"2018-05", "title"=>"May 2018", "sum"=>58.0},
        {"id"=>"2018-06", "title"=>"June 2018", "sum"=>4.0},
        {"id"=>"2018-08", "title"=>"August 2018", "sum"=>16.0},
        {"id"=>"2019-02", "title"=>"February 2019", "sum"=>11.0},
        {"id"=>"2019-03", "title"=>"March 2019", "sum"=>5.0},
        {"id"=>"2019-04", "title"=>"April 2019", "sum"=>2.0},
        {"id"=>"2019-05", "title"=>"May 2019", "sum"=>1.0}])
    end

    it "subj_id" do
      subj_id = "https://doi.org/10.3389/feart.2018.00153"
      response = Event.query(nil, subj_id: subj_id)
      expect(response[:data].size).to eq(1)
      expect(response[:data].first).to eq(:id=>"63897322-b0fd-4145-a3a7-014b37954aed", :subj_id=>"https://doi.org/10.3389/feart.2018.00153", :obj_id=>"https://doi.org/10.3886/icpsr04254.v1", :source_id=>"crossref", :relation_type_id=>"references", :total=>1)
      expect(response.dig(:meta, "relationTypes", 0, "yearMonths")).to eq([{"id"=>"0000-01", "sum"=>1.0, "title"=>"January 0000"}])
    end

    it "obj_id" do
      obj_id = "https://doi.org/10.7272/q6z60kzd"
      response = Event.query(nil, obj_id: obj_id)
      expect(response[:data].size).to eq(22)
      expect(response[:data].first).to eq(:id=>"758199db-95c9-4216-ae7a-70b9d00425d4", :subj_id=>"https://api.datacite.org/reports/08761bb6-f8d9-4d01-8012-fd21042fd71d", :obj_id=>"https://doi.org/10.7272/q6z60kzd", :source_id=>"datacite-usage", :relation_type_id=>"total-dataset-investigations-regular", :total=>58)
      expect(response.dig(:meta, "relationTypes", 0, "yearMonths")).to eq([{"id"=>"2018-04", "title"=>"April 2018", "sum"=>23171.0},
        {"id"=>"2018-05", "title"=>"May 2018", "sum"=>58.0},
        {"id"=>"2018-06", "title"=>"June 2018", "sum"=>4.0},
        {"id"=>"2018-08", "title"=>"August 2018", "sum"=>16.0},
        {"id"=>"2019-02", "title"=>"February 2019", "sum"=>11.0},
        {"id"=>"2019-03", "title"=>"March 2019", "sum"=>5.0},
        {"id"=>"2019-04", "title"=>"April 2019", "sum"=>2.0},
        {"id"=>"2019-05", "title"=>"May 2019", "sum"=>2.0}])
    end

    it "not found" do
      source_id = "xxx"
      response = Event.query(nil, source_id: source_id)
      expect(response[:data]).to be_empty
      expect(response[:meta]).to eq("page"=>1, "total"=>0, "totalPages"=>0)
    end
  end
end