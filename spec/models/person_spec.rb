require 'rails_helper'

describe Person, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://orcid.org/0000-0003-2706-4082"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-2706-4082")
      expect(person.name).to eq("Agnes Ebenberger")
      expect(person.given_name).to eq("Agnes")
      expect(person.family_name).to eq("Ebenberger")
    end

    it "also found" do
      id = "https://orcid.org/0000-0003-3484-6875"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-3484-6875")
      expect(person.name).to eq("K. J. Garza")
      expect(person.given_name).to eq("Kristian")
      expect(person.family_name).to eq("Garza")
    end

    it "not found" do
      id = "https://orcid.org/xxxxx"
      people = Person.find_by_id(id)
      expect(people[:data]).to be_nil
      expect(people[:errors]).to be_nil
    end
  end

  describe "query" do
    it "found all" do
      query = nil
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(8827698)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-5387-6407")
      expect(person.name).to eq("Mohammed Al-Dhahir")
      expect(person.given_name).to eq("Mohammed")
      expect(person.family_name).to eq("Al-Dhahir")
      expect(person.other_names).to eq(["Mohammed Ali Al-Dhahir"])
      expect(person.affiliation).to eq([{"name"=>"AOSpine International"},
        {"name"=>"Al-Ra'afa Medical Centre"},
        {"name"=>"Al-Thawra Modren General Hospital"},
        {"name"=>"Al-mustansiryia- college of Medicine"},
        {"name"=>"Alsamawah General Hospital"},
        {"name"=>"Arab Board of Health Specializations"},
        {"name"=>"University of Rochester"},
        {"name"=>"Yemeni German Hospital"}])
    end

    it "found miller" do
      query = "miller"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(7373)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-1360-1118")
      expect(person.name).to eq("David Justin Miller")
      expect(person.given_name).to eq("David")
      expect(person.family_name).to eq("Justin Miller")
      expect(person.affiliation).to eq([{"name"=>"Regents School of Austin"}])
    end

    it "found datacite" do
      query = "datacite"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(15414)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-9300-5278")
      expect(person.name).to eq("Patricia Cruse")
      expect(person.given_name).to eq("Patricia")
      expect(person.family_name).to eq("Cruse")
      expect(person.other_names).to eq(["Trisha Cruse"])
      expect(person.affiliation).to eq([{"name"=>"DataCite"}, {"name"=>"University of California Berkeley"}])
    end
  end
end
