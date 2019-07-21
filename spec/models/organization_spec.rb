require 'rails_helper'

describe Organization, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://ror.org/0521rfb23"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/0521rfb23")
      expect(organization.name).to eq("Lincoln University")
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
      expect(organizations.dig(:meta, "total")).to eq(91625)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/00xqf8t64")
      expect(organization.name).to eq("Padjadjaran University")
      expect(organization.labels).to eq([{"code"=>"ID", "name"=>"Universitas Padjadjaran"}])
      expect(organization.links).to eq(["http://www.unpad.ac.id/en/"])
    end

    it "found" do
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(10475)
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
  end
end