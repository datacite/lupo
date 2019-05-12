require 'rails_helper'

describe Organization, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://ror.org/0521rfb23"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      expect(organizations[:data].first).to eq(:id=>"https://ror.org/0521rfb23", :name=>"Lincoln University", :aliases=>["Ashmun Institute"], :acronyms=>["LU"], :labels=>[{:iso639=>"es", :label=>"Universidad Lincoln"}], :links=>["http://www.lincoln.edu/"], :wikipedia_url=>"http://en.wikipedia.org/wiki/Lincoln_University_(Pennsylvania)", :country=>{:id=>"US", :name=>"United States"})
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
      expect(organizations[:data].first).to eq(:id=>"https://ror.org/00xqf8t64", :name=>"Padjadjaran University", :aliases=>["Padjadjaran University"], :acronyms=>["UNPAD"], :labels=> [{:iso639=>"id", :label=>"Universitas Padjadjaran"}], :links=>["http://www.unpad.ac.id/en/"], :wikipedia_url=>"http://en.wikipedia.org/wiki/Padjadjaran_University", :country=>{:id=>"ID", :name=>"Indonesia"})
    end

    it "found" do
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(10475)
      expect(organizations[:data].size).to eq(20)
      expect(organizations[:data].first).to eq(:id=>"https://ror.org/04ps1r162", :name=>"Lincoln University", :aliases=>[], :acronyms=>[], :labels=>[{:iso639=>"mi", :label=>"Te Whare Wanaka o Aoraki"}], :links=>["http://www.lincoln.ac.nz/"], :wikipedia_url=>"http://en.wikipedia.org/wiki/Lincoln_University_(New_Zealand)", :country=>{:id=>"NZ", :name=>"New Zealand"})
    end

    it "not found" do
      query = "xxx"
      organizations = Organization.query(query)
      expect(organizations[:data]).to be_empty
    end
  end
end