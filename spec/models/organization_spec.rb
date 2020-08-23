require 'rails_helper'

describe Organization, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://ror.org/0521rfb23"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/0521rfb23")
      expect(organization.name).to eq("Lincoln University - Pennsylvania")
      expect(organization.labels).to eq([{"code"=>"ES", "name"=>"Universidad Lincoln"}])
      expect(organization.links).to eq(["http://www.lincoln.edu/"])
    end

    it "not found" do
      id = "https://doi.org/10.13039/xxx"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data]).to be_nil
      expect(organizations[:errors]).to be_nil
    end
  end

  describe "query" do
    it "all" do
      query = nil
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(98332)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/027bk5v43")
      expect(organization.name).to eq("Illinois Department of Public Health")
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(["http://www.dph.illinois.gov/"])
    end

    it "found" do
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(10764)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/04ps1r162")
      expect(organization.name).to eq("Lincoln University")
      expect(organization.labels).to eq([{"code"=>"MI", "name"=>"Te Whare Wanaka o Aoraki"}])
      expect(organization.links).to eq(["http://www.lincoln.ac.nz/"])
    end

    it "found with umlaut" do
      query = "münster"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(10)
      expect(organizations[:data].size).to eq(10)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/01856cw59")
      expect(organization.name).to eq("University Hospital Münster")
      expect(organization.labels).to eq([{"code"=>"DE", "name"=>"Universitätsklinikum Münster"}])
      expect(organization.links).to eq(["http://klinikum.uni-muenster.de/"])
    end

    it "found page 2" do
      query = "lincoln university"
      organizations = Organization.query(query, offset: 2)
      expect(organizations.dig(:meta, "total")).to eq(10764)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/01qb09m39")
      expect(organization.name).to eq("Lincoln Agritech (New Zealand)")
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(["https://www.lincolnagritech.co.nz/"])
    end

    it "found by types government" do
      organizations = Organization.query(nil, types: "government")
      expect(organizations.dig(:meta, "total")).to eq(5762)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/027bk5v43")
      expect(organization.name).to eq("Illinois Department of Public Health")
      expect(organization.types).to eq(["Government"])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(["http://www.dph.illinois.gov/"])
    end

    it "found by country gb" do
      organizations = Organization.query(nil, country: "gb")
      expect(organizations.dig(:meta, "total")).to eq(7166)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/04jzmdh37")
      expect(organization.name).to eq("Centre for Economic Policy Research")
      expect(organization.types).to eq(["Nonprofit"])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(["http://www.cepr.org/"])
    end

    it "found by types and country" do
      organizations = Organization.query(nil, types: "government", country: "gb")
      expect(organizations.dig(:meta, "total")).to eq(314)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/04jswqb94")
      expect(organization.name).to eq("Defence Science and Technology Laboratory")
      expect(organization.types).to eq(["Government"])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(["https://www.gov.uk/government/organisations/defence-science-and-technology-laboratory"])
    end

    it "not found" do
      query = "xxx"
      organizations = Organization.query(query)
      expect(organizations[:data]).to be_empty
    end

    it "status code not 200" do
      url = "https://api.ror.org/organizations?query=lincoln%20university&page=1"
      stub = stub_request(:get, url).and_return(status: [408])
      
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations).to be_empty
      expect(stub).to have_been_requested
    end
  end
end