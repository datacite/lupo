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
      expect(person.description).to be_nil
      expect(person.links).to be_empty
      expect(person.identifiers).to be_empty
      expect(person.country).to be_nil
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
      expect(person.alternate_name).to eq(["Kristian Javier Garza Gutierrez"])
      expect(person.description).to be_nil
      expect(person.links).to eq([{"name"=>"Mendeley profile", "url"=>"https://www.mendeley.com/profiles/kristian-g/"}])
      expect(person.identifiers).to eq([{"identifier"=>"kjgarza",
        "identifierType"=>"GitHub",
        "identifierUrl"=>"https://github.com/kjgarza"}])
      expect(person.country).to eq("id"=>"DE", "name"=>"Germany")
    end

    it "found with biography" do
      id = "https://orcid.org/0000-0003-1419-2405"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-1419-2405")
      expect(person.name).to eq("Martin Fenner")
      expect(person.given_name).to eq("Martin")
      expect(person.family_name).to eq("Fenner")
      expect(person.alternate_name).to eq(["M Fenner", "MH Fenner", "Martin H. Fenner", "Martin Hellmut Fenner"])
      expect(person.description).to eq("Martin Fenner is the DataCite Technical Director and manages the technical architecture for Datacite. From 2012 to 2015 he was the technical lead for the PLOS Article-Level Metrics project. Martin has a medical degree from the Free University of Berlin and is a Board-certified medical oncologist.")
      expect(person.links).to eq([{ "name" => "My SciENCV", "url"=>"http://www.ncbi.nlm.nih.gov/myncbi/mfenner/cv/1413/" }, 
        { "name"=>"Twitter", "url"=>"http://twitter.com/mfenner" },
        { "name"=>"Blog", "url"=>"http://blog.martinfenner.org" }])
      expect(person.identifiers).to eq([{"identifier"=>"7006600825",
        "identifierType"=>"Scopus Author ID",
        "identifierUrl"=>
        "http://www.scopus.com/inward/authorDetails.url?authorID=7006600825&partnerID=MN8TOARS"},
       {"identifier"=>"000000035060549X",
        "identifierType"=>"ISNI",
        "identifierUrl"=>"http://isni.org/000000035060549X"},
        {"identifier"=>"mfenner",
         "identifierType"=>"GitHub",
         "identifierUrl"=>"https://github.com/mfenner"}])
      expect(person.country).to eq("id"=>"DE", "name"=>"Germany")
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
      expect(person.description).to be_nil
      expect(person.links).to be_empty
      expect(person.identifiers).to be_empty
      expect(person.country).to be_nil
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
      expect(person.description).to be_nil
      expect(person.links).to be_empty
      expect(person.identifiers).to be_empty
      expect(person.country).to be_nil
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
      expect(person.alternate_name).to eq([])
      expect(person.description).to be_nil
      expect(person.links).to be_empty
      expect(person.identifiers).to be_empty
      expect(person.country).to be_nil
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
      expect(person.description).to be_nil
      expect(person.links).to be_empty
      expect(person.identifiers).to be_empty
      expect(person.country).to be_nil
    end
  end
end
