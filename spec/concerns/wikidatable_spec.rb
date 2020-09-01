require 'rails_helper'

describe "Organization", vcr: true do
  subject { Organization }

  context "find_by_wikidata_id" do
    it 'for entity' do
      id = "Q35794"
      result = subject.find_by_wikidata_id(id)
      organization = result[:data].first

      expect(organization.id).to eq("Q35794")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.description).to eq("Collegiate public research university in Cambridge, England, United Kingdom.")
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception).to eq("1209-01-01")
      expect(organization.geolocation).to eq("latitude"=>52.205277777778, "longitude"=>0.11722222222222)
      expect(organization.geonames).to eq("7288046")
      expect(organization.ringgold).to eq("2152")
    end
  end

  context "fetch_wikidata_by_id" do
    it 'for entity' do
      id = "Q35794"
      response = subject.fetch_wikidata_by_id(id)

      expect(response.dig("data", "entities", id, "labels", "en", "value")).to eq("University of Cambridge")
      expect(response.dig("data", "entities", id, "descriptions", "en", "value")).to eq("collegiate public research university in Cambridge, England, United Kingdom")

      claims = response.dig("data", "entities", id, "claims") || {}
      expect(claims.dig("P2002", 0, "mainsnak", "datavalue", "value")).to eq("Cambridge_Uni")
      expect(claims.dig("P571", 0, "mainsnak", "datavalue", "value", "time")).to eq("+1209-01-01T00:00:00Z")
    end
  end

  context "parse_wikidata_message" do
    it 'for entity' do
      id = "Q35794"
      message = subject.fetch_wikidata_by_id(id).dig("data")
      organization = subject.parse_wikidata_message(id: id, message: message)

      expect(organization.id).to eq("Q35794")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.description).to eq("Collegiate public research university in Cambridge, England, United Kingdom.")
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception).to eq("1209-01-01")
      expect(organization.geolocation).to eq("latitude"=>52.205277777778, "longitude"=>0.11722222222222)
      expect(organization.geonames).to eq("7288046")
      expect(organization.ringgold).to eq("2152")
    end
  end
end

describe "Person", vcr: true do
  subject { Person }

  context "wikidata_query" do
    it "employment" do
      orcid = "0000-0003-1419-2405"
      employments = subject.get_orcid(orcid: orcid, endpoint: "employments")
      employment = subject.get_employments(employments)
      response = subject.wikidata_query(employment)

      expect(response).to eq([{"organizationName"=>"DataCite","roleTitle"=>"Technical Director","startDate"=>"2015-08-01T00:00:00Z"},
        {"organizationName"=>"Medizinische Hochschule Hannover", "startDate"=>"2005-11-01T00:00:00Z", "endDate"=>"2017-05-01T00:00:00Z", "organizationId"=>"https://ror.org/00f2yqf98"}, 
        {"organizationName"=>"Public Library of Science", "roleTitle"=>"Technical lead article-level metrics project (contractor)", "startDate"=>"2012-04-01T00:00:00Z", "endDate"=>"2015-07-01T00:00:00Z", "organizationId"=>"https://ror.org/008zgvp64"}, 
        {"organizationName"=>"Charité Universitätsmedizin Berlin", "startDate"=>"1998-09-01T00:00:00Z", "endDate"=>"2005-10-01T00:00:00Z", "organizationId"=>"https://ror.org/001w7jn25"}])
    end

    it "empty" do
      employment = nil
      response = subject.wikidata_query(employment)
      expect(response).to be_empty
    end
  end
end
