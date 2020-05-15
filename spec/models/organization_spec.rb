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
      expect(organizations.dig(:meta, "total")).to eq(97819)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/02x66tk73")
      expect(organization.name).to eq("Egypt-Japan University of Science and Technology")
      expect(organization.labels).to eq([{"code"=>"AR", "name"=>"الجامعة المصرية اليابانية للعلوم والتكنولوجيا‎"}])
      expect(organization.links).to eq(["https://ejust.edu.eg"])
    end

    it "found" do
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(10718)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/04ps1r162")
      expect(organization.name).to eq("Lincoln University")
      expect(organization.labels).to eq([{"code"=>"MI", "name"=>"Te Whare Wanaka o Aoraki"}])
      expect(organization.links).to eq(["http://www.lincoln.ac.nz/"])
    end

    it "not found" do
      query = "xxx"
      organizations = Organization.query(query)
      expect(organizations[:data]).to be_empty
    end

    it "status code not 200" do
      url = "https://api.ror.org/organizations?query=lincoln%20university"
      stub = stub_request(:get, url).and_return(status: [408])
      
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations).to be_empty
      expect(stub).to have_been_requested
    end
  end
end