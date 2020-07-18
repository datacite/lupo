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
      expect(person.alternate_name).to eq([])
      expect(person.affiliation).to eq([])
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
      expect(person.alternate_name).to eq([])
      expect(person.affiliation).to eq([])
    end

    it "found with X in ID" do
      id = "https://orcid.org/0000-0001-7701-701X"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0001-7701-701X")
      expect(person.name).to eq("Rory O'Bryen")
      expect(person.given_name).to eq("Rory")
      expect(person.family_name).to eq("O'Bryen")
      expect(person.alternate_name).to eq([])
      expect(person.affiliation).to eq([])
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
      expect(people.dig(:meta, "total")).to eq(9229580)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-5387-6407")
      expect(person.name).to eq("Mohammed Al-Dhahir")
      expect(person.given_name).to eq("Mohammed")
      expect(person.family_name).to eq("Al-Dhahir")
      expect(person.alternate_name).to eq(["Mohammed Ali Al-Dhahir"])
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
      expect(people.dig(:meta, "total")).to eq(7660)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-2131-0054")
      expect(person.name).to eq("Edmund Miller")
      expect(person.given_name).to eq("Edmund")
      expect(person.family_name).to eq("Miller")
      expect(person.affiliation).to eq([{"name"=>"ABT"},
        {"name"=>"Feinstein Institute for Medical Research"},
        {"name"=>"Hofstra Northwell School of Medicine at Hofstra University"},
        {"name"=>"King's College London"},
        {"name"=>"RDS2 Solutions"},
        {"name"=>"Royal Society of Chemistry"},
        {"name"=>"University of Texas Health Northeast"}])
    end

    it "found datacite" do
      query = "datacite"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(15825)
      expect(people.dig(:data).size).to eq(25)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-9300-5278")
      expect(person.name).to eq("Patricia Cruse")
      expect(person.given_name).to eq("Patricia")
      expect(person.family_name).to eq("Cruse")
      expect(person.alternate_name).to eq(["Trisha Cruse"])
      expect(person.affiliation).to eq([{"name"=>"DataCite"}, {"name"=>"University of California Berkeley"}])
    end
  end
end
