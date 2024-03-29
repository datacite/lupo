# frozen_string_literal: true

require "rails_helper"

describe Person, type: :model, vcr: true do
  describe "find_by_id" do
    xit "found" do
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
      expect(person.employment.length).to eq(0)
    end

    xit "also found" do
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
      expect(person.links).to eq(
        [
          {
            "name" => "Mendeley profile",
            "url" => "https://www.mendeley.com/profiles/kristian-g/",
          },
          { "name" => "github", "url" => "https://github.com/kjgarza" },
        ],
      )
      expect(person.identifiers).to eq(
        [
          {
            "identifier" => "kjgarza",
            "identifierType" => "GitHub",
            "identifierUrl" => "https://github.com/kjgarza",
          },
        ],
      )
      expect(person.country).to eq("id" => "DE", "name" => "Germany")
      expect(person.employment.length).to eq(1)
      expect(person.employment).to eq(
        [
          {
            "organization_name" => "DataCite",
            "role_title" => "Application Developer",
            "start_date" => "2016-08-01T00:00:00Z",
          },
        ],
      )
    end

    xit "found with biography" do
      id = "https://orcid.org/0000-0003-1419-2405"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0003-1419-2405")
      expect(person.name).to eq("Martin Fenner")
      expect(person.given_name).to eq("Martin")
      expect(person.family_name).to eq("Fenner")
      expect(person.alternate_name).to eq(["Martin Hellmut Fenner"])
      expect(person.description).to eq(
        "Martin Fenner is the DataCite Technical Director since 2015. From 2012 to 2015 he was the technical lead for the PLOS Article-Level Metrics project. Martin has a medical degree from the Free University of Berlin and is a Board-certified medical oncologist.",
      )
      expect(person.links).to eq(
        [{ "name" => "Twitter", "url" => "http://twitter.com/mfenner" }],
      )
      expect(person.identifiers).to eq(
        [
          {
            "identifier" => "7006600825",
            "identifierType" => "Scopus Author ID",
            "identifierUrl" =>
              "http://www.scopus.com/inward/authorDetails.url?authorID=7006600825&partnerID=MN8TOARS",
          },
          {
            "identifier" => "000000035060549X",
            "identifierType" => "ISNI",
            "identifierUrl" => "http://isni.org/000000035060549X",
          },
          {
            "identifier" => "mfenner",
            "identifierType" => "GitHub",
            "identifierUrl" => "https://github.com/mfenner",
          },
        ],
      )
      expect(person.country).to eq("id" => "DE", "name" => "Germany")
      expect(person.employment).to eq(
        [
          {
            "organization_id" => "https://grid.ac/institutes/grid.475826.a",
            "organization_name" => "DataCite",
            "role_title" => "Technical Director",
            "start_date" => "2015-08-01T00:00:00Z",
          },
          {
            "end_date" => "2017-05-01T00:00:00Z",
            "organization_id" => "https://grid.ac/institutes/grid.10423.34",
            "organization_name" => "Hannover Medical School",
            "role_title" => "Clinical Fellow in Hematology and Oncology",
            "start_date" => "2005-11-01T00:00:00Z",
          },
          {
            "end_date" => "2015-07-01T00:00:00Z",
            "organization_name" => "Public Library of Science",
            "role_title" =>
              "Technical lead article-level metrics project (contractor)",
            "start_date" => "2012-04-01T00:00:00Z",
          },
          {
            "end_date" => "2005-10-01T00:00:00Z",
            "organization_name" => "Charité Universitätsmedizin Berlin",
            "role_title" => "Resident in Internal Medicine",
            "start_date" => "1998-09-01T00:00:00Z",
          },
        ],
      )
    end

    xit "found with X in ID" do
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
      expect(person.employment.length).to eq(1)
      expect(person.employment).to eq(
        [
          {
            "organization_name" => "University of Cambridge",
            "role_title" =>
              "Senior Lecturer in Latin American Literature and Culture",
            "start_date" => "2006-01-01T00:00:00Z",
          },
        ],
      )
    end

    it "found with utf8" do
      id = "https://sandbox.orcid.org/0000-0002-5721-4355"
      people = Person.find_by_id(id)
      expect(people[:data].size).to eq(1)
      person = people[:data].first
      expect(person.id).to eq("https://orcid.org/0000-0002-5721-4355")
      expect(person.given_name).to eq("DataCíté")
      expect(person.family_name).to eq("UTF8 Tést")
    end

    xit "account locked" do
      id = "https://orcid.org/0000-0003-1315-5960"
      expect { Person.find_by_id(id) }.to raise_error(
        Faraday::ClientError,
        /ORCID record is locked/,
      )
    end

    xit "not found" do
      id = "https://orcid.org/xxxxx"
      people = Person.find_by_id(id)
      expect(people[:data]).to be_nil
      expect(people[:errors]).to be_nil
    end
  end

  describe "query" do
    xit "found all" do
      query = nil
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(9_229_580)
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

    xit "found miller" do
      query = "miller"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(7_660)
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

    xit "found datacite" do
      query = "datacite"
      people = Person.query(query)
      expect(people.dig(:meta, "total")).to eq(15_825)
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

    xit "handle errors gracefully" do
      query = "container.identifier:2658-719X"
      expect { Person.query(query) }.to raise_error(
        Faraday::ClientError,
        /Error from server/,
      )
    end
  end
end
