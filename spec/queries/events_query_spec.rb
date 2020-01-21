# frozen_string_literal: true

require "rails_helper"

describe EventsQuery, elasticsearch: true do

  context "citation events" do
    let!(:event) { create(:event_for_datacite_related,  subj_id:"http://doi.org/10.0260/co.2004960.v2", obj_id:"http://doi.org/10.0260/co.2004960.v1") }
    let!(:event_references) { create_list(:event_for_datacite_related, 3, obj_id:"10.5061/dryad.47sd5/2", relation_type_id: "references") }
    let!(:copies) { create(:event_for_datacite_related,  subj_id:"http://doi.org/10.0260/co.2004960.v2", obj_id:"http://doi.org/10.0260/co.2004960.v1", relation_type_id: "cites") }

    before do
      Event.import
      sleep 1
    end

    it "doi_citations" do
      expect(EventsQuery.new.doi_citations("10.0260/co.2004960.v1")).to eq(1)
    end

    it "doi_citations wiht 0 citations" do
      expect(EventsQuery.new.doi_citations("10.5061/dryad.dd47sd5/1")).to eq(0)
    end

    it "citations" do
      results = EventsQuery.new.citations("10.5061/dryad.47sd5/1,10.5061/dryad.47sd5/2,10.0260/co.2004960.v1")
      citations = results.select { |item| item[:id] == "10.5061/dryad.47sd5/2" }.first
      no_citations = results.select { |item| item[:id] == "10.5061/dryad.47sd5/1" }.first
      
      expect(citations[:citations]).to eq(3)
      # expect(no_citations[:count]).to eq(0)
    end
  end


  context "usage events" do
    let!(:views) { create_list(:event_for_datacite_usage, 1,  obj_id:"http://doi.org/10.0260/co.2004960.v1", relation_type_id:"unique-dataset-investigations-regular") }
    let!(:downloads) { create_list(:event_for_datacite_usage, 1,  obj_id:"http://doi.org/10.0260/co.2004960.v1", relation_type_id:"unique-dataset-requests-regular") }

    before do
      Event.import
      sleep 1
    end

    it "doi_views" do
      expect(EventsQuery.new.doi_views("10.0260/co.2004960.v1")).to eq(views.first.total)
    end

    it "doi_downloads" do
      expect(EventsQuery.new.doi_downloads("10.0260/co.2004960.v1")).to eq(downloads.first.total)
    end

    it "usage" do
      expect(EventsQuery.new.usage("10.0260/co.2004960.v1").first).to eq(id: "https://doi.org/10.0260/co.2004960.v1", title: "https://doi.org/10.0260/co.2004960.v1", relationTypes: [{ id: "unique-dataset-requests-regular", title: "unique-dataset-requests-regular", sum: downloads.first.total }, { id: "unique-dataset-investigations-regular", title: "unique-dataset-investigations-regular", sum: views.first.total }])
    end
  end

  context "mutiple usage events" do
    let!(:views) { create_list(:event_for_datacite_usage, 5, relation_type_id:"unique-dataset-investigations-regular") }
    let!(:downloads) { create_list(:event_for_datacite_usage, 7, relation_type_id:"unique-dataset-requests-regular") }

    before do
      Event.import
      sleep 1
    end

    it "show views" do
      response = EventsQuery.new.views( views.map { |view| view.doi }.join(','))
      # expect(response.size).to eq(5)
      expect(response.first[:views]).to be > 0
    end

    it "show downloads" do
      puts downloads.map { |download| download.doi }.join(',')
      response = EventsQuery.new.downloads(downloads.map { |download| download.doi }.join(','))
      # expect(response.size).to eq(5)
      expect(response.first[:downloads]).to be > 0
    end
  end
end
