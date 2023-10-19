# frozen_string_literal: true

require "rails_helper"

describe Doi, vcr: true do
  let(:xml) { file_fixture("datacite.xml").read }

  subject { DataciteDoisController.new }

  context "clean_xml" do
    it "clean_xml" do
      string = file_fixture("datacite.xml").read
      expect(subject.from_xml(string)).to eq(string)
    end

    it "clean_xml malformed" do
      string = file_fixture("datacite_malformed.xml").read
      expect { subject.clean_xml(string) }.to raise_error(
        Nokogiri::XML::SyntaxError,
        /FATAL: Premature end of data in tag resource/,
      )
    end

    it "clean_xml namespace" do
      string = file_fixture("datacite_namespace.xml").read
      expect(subject.clean_xml(string)).to start_with("<?xml version=\"1.0\"")
    end

    it "clean_xml utf-8 bom" do
      string = file_fixture("utf-8_bom.xml").read
      expect(subject.clean_xml(string)).to start_with(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      )
    end

    it "clean_xml utf-16" do
      string = file_fixture("utf-16.xml").read
      expect(subject.clean_xml(string)).to start_with(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      )
    end
  end

  context "from_xml" do
    it "from_xml" do
      string = file_fixture("datacite.xml").read
      expect(subject.from_xml(string)).to eq(string)
    end

    it "from_xml malformed" do
      string = file_fixture("datacite_malformed.xml").read
      expect { subject.from_xml(string) }.to raise_error(
        Nokogiri::XML::SyntaxError,
        /FATAL: Premature end of data in tag resource/,
      )
    end
  end

  context "from_json" do
    it "from_json" do
      string = file_fixture("citeproc.json").read
      expect(subject.from_json(string)).to eq(string)
    end

    it "from_json starts with unexpected character" do
      string = file_fixture("datacite.xml").read
      expect { subject.from_json(string) }.to raise_error(
        JSON::ParserError,
        /Empty input \(after \) at line 1, column 1/,
      )
    end

    it "from_json malformed" do
      string = file_fixture("citeproc_malformed.json").read
      expect { subject.from_json(string) }.to raise_error(
        JSON::ParserError,
        /expected comma, not a string \(after id\) at line 4, column 9/,
      )
    end

    it "from_json duplicate keys" do
      string = file_fixture("citeproc_duplicate_keys.json").read
      expect { subject.from_json(string) }.to raise_error(
        JSON::ParserError,
        "The same key is defined more than once: id",
      )
    end
  end

  context "well_formed_xml" do
    it "from_xml" do
      string = file_fixture("datacite.xml").read
      expect(subject.well_formed_xml(string)).to eq(string)
    end

    it "from_xml malformed" do
      string = file_fixture("datacite_malformed.xml").read
      expect { subject.well_formed_xml(string) }.to raise_error(
        Nokogiri::XML::SyntaxError,
        /FATAL: Premature end of data in tag resource/,
      )
    end

    it "from_json" do
      string = file_fixture("citeproc.json").read
      expect(subject.well_formed_xml(string)).to eq(string)
    end

    it "from_json starts with unexpected character" do
      string = "abc"
      expect { subject.well_formed_xml(string) }.to raise_error(
        JSON::ParserError,
        /Empty input \(after \) at line 1, column 1/,
      )
    end

    it "from_json malformed" do
      string = file_fixture("citeproc_malformed.json").read
      expect { subject.well_formed_xml(string) }.to raise_error(
        JSON::ParserError,
        /expected comma/,
      )
    end

    it "from_json duplicate keys" do
      string = file_fixture("citeproc_duplicate_keys.json").read
      expect { subject.well_formed_xml(string) }.to raise_error(
        JSON::ParserError,
        "The same key is defined more than once: id",
      )
    end
  end

  context "get_content_type" do
    it "datacite" do
      string = file_fixture("datacite.xml").read
      expect(subject.get_content_type(string)).to eq("xml")
    end

    it "crossref" do
      string = file_fixture("crossref.xml").read
      expect(subject.get_content_type(string)).to eq("xml")
    end

    it "crosscite" do
      string = file_fixture("crosscite.json").read
      expect(subject.get_content_type(string)).to eq("json")
    end

    it "schema_org" do
      string = file_fixture("schema_org.json").read
      expect(subject.get_content_type(string)).to eq("json")
    end

    it "codemeta" do
      string = file_fixture("codemeta.json").read
      expect(subject.get_content_type(string)).to eq("json")
    end

    it "datacite_json" do
      string = file_fixture("datacite.json").read
      expect(subject.get_content_type(string)).to eq("json")
    end

    it "bibtex" do
      string = file_fixture("crossref.bib").read
      expect(subject.get_content_type(string)).to eq("string")
    end

    it "ris" do
      string = file_fixture("crossref.ris").read
      expect(subject.get_content_type(string)).to eq("string")
    end
  end

  context "parse_xml" do
    it "from schema 4" do
      string = file_fixture("datacite.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("datacite")
      expect(meta["doi"]).to eq("10.14454/4k3m-nyvg")
      expect(meta["creators"]).to eq(
        [
          {
            "familyName" => "Fenner",
            "givenName" => "Martin",
            "name" => "Fenner, Martin",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
                "nameIdentifierScheme" => "ORCID",
                "schemeUri" => "https://orcid.org",
              },
            ],
          },
        ],
      )
      expect(meta["titles"]).to eq([{ "title" => "Eating your own Dog Food" }])
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "DataCite"
        }
      )
    end

    it "from schema 3" do
      string = file_fixture("datacite_schema_3.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("datacite")
      expect(meta["doi"]).to eq("10.5061/dryad.8515")
      expect(meta["creators"].length).to eq(8)
      expect(meta["creators"].first).to eq(
        "familyName" => "Ollomo",
        "givenName" => "Benjamin",
        "name" => "Ollomo, Benjamin",
        "nameType" => "Personal",
        "nameIdentifiers" => [],
        "affiliation" => [],
      )
      expect(meta["titles"]).to eq(
        [{ "title" => "Data from: A new malaria agent in African hominids." }],
      )
      expect(meta["publication_year"]).to eq("2011")
      expect(meta["publisher"]).to eq(
        {
          "name" => "Dryad Digital Repository"
        }
      )
    end

    it "from schema 2.2" do
      string = file_fixture("datacite_schema_2.2.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("datacite")
      expect(meta["doi"]).to eq("10.14454/testpub")
      expect(meta["creators"]).to eq(
        [
          {
            "familyName" => "Smith",
            "givenName" => "John",
            "name" => "Smith, John",
            "nameType" => "Personal",
            "nameIdentifiers" => [],
            "affiliation" => [],
          },
          {
            "name" => "つまらないものですが",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "abc123", "nameIdentifierScheme" => "ISNI"
              },
            ],
            "affiliation" => [],
          },
        ],
      )
      expect(meta["titles"]).to eq(
        [
          { "title" => "Właściwości rzutowań podprzestrzeniowych" },
          {
            "title" => "Translation of Polish titles",
            "titleType" => "TranslatedTitle",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2010")
      expect(meta["publisher"]).to eq(
        {
          "name" => "Springer"
        }
      )
    end

    it "from schema 4 missing creators" do
      string = file_fixture("datacite_missing_creator.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("datacite")
      expect(meta["doi"]).to eq("10.5438/4k3m-nyvg")
      expect(meta["creators"]).to be_empty
      expect(meta["titles"]).to eq([{ "title" => "Eating your own Dog Food" }])
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "DataCite"
        }
      )
    end

    it "from namespaced xml" do
      string = file_fixture("ns0.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("datacite")
      # TODO
      # expect(meta["doi"]).to eq("10.5438/4k3m-nyvg")
      # expect(meta["creators"]).to be_empty
      # expect(meta["titles"]).to eq([{"title"=>"Eating your own Dog Food"}])
      # expect(meta["publication_year"]).to eq("2016")
      # expect(meta["publisher"]).to eq("DataCite")
    end

    it "from crossref" do
      string = file_fixture("crossref.xml").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("crossref")
      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "affiliation" => [
          {
            "name" =>
              "Department of Plant Molecular Biology, University of Lausanne, Lausanne, Switzerland",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "eLife Sciences Publications, Ltd"
        }
      )
      expect(meta["container"]).to eq(
        "firstPage" => "e01567",
        "identifier" => "2050-084X",
        "identifierType" => "ISSN",
        "title" => "eLife",
        "type" => "Journal",
        "volume" => "3",
      )
    end

    it "from crossref url" do
      string = "https://doi.org/10.7554/elife.01567"
      meta = subject.parse_xml(string)

      expect(meta["from"]).to eq("crossref")
      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "affiliation" => [
          {
            "name" =>
              "Department of Plant Molecular Biology, University of Lausanne, Lausanne, Switzerland",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "eLife Sciences Publications, Ltd"
        }
      )
      expect(meta["container"]).to eq(
        "firstPage" => "e01567",
        "identifier" => "2050-084X",
        "identifierType" => "ISSN",
        "title" => "eLife",
        "type" => "Journal",
        "volume" => "3",
      )
      expect(meta["agency"]).to eq("crossref")
    end

    # it "from datacite url" do
    #   string = "10.14454/1x4x-9056"
    #   meta = subject.parse_xml(string)
    #   expect(meta["from"]).to eq("datacite")
    #   expect(meta["doi"]).to eq("10.14454/1x4x-9056")
    #   expect(meta["creators"].length).to eq(1)
    #   expect(meta["creators"].first).to eq(
    #     "familyName" => "Fenner",
    #     "givenName" => "Martin",
    #     "name" => "Fenner, Martin",
    #     "nameIdentifiers" => [
    #       {
    #         "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
    #         "nameIdentifierScheme" => "ORCID",
    #         "schemeUri" => "https://orcid.org",
    #       },
    #     ],
    #     "nameType" => "Personal",
    #   )
    #   expect(meta["titles"]).to eq([{ "title" => "Cool DOI's" }])
    #   expect(meta["publication_year"]).to eq("2016")
    #   expect(meta["publisher"]).to eq("DataCite")
    #   expect(meta["agency"]).to eq("datacite")
    # end

    it "from bibtex" do
      string = file_fixture("crossref.bib").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("bibtex")
      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "{eLife} Sciences Organisation, Ltd."
        }
      )
      expect(meta["container"]).to eq(
        "identifier" => "2050-084X",
        "identifierType" => "ISSN",
        "title" => "eLife",
        "type" => "Journal",
        "volume" => "3",
      )
    end

    it "from ris" do
      string = file_fixture("crossref.ris").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("ris")
      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "nameType" => "Personal",
        "nameIdentifiers" => [],
        "affiliation" => [],
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "(:unav)"
        }
      )
      expect(meta["container"]).to eq(
        "title" => "eLife", "type" => "Journal", "volume" => "3",
      )
    end

    it "from codemeta" do
      string = file_fixture("codemeta.json").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("codemeta")
      expect(meta["doi"]).to eq("10.5063/f1m61h5x")
      expect(meta["creators"].length).to eq(3)
      expect(meta["creators"].first).to eq(
        "affiliation" => [{ "name" => "NCEAS" }],
        "familyName" => "Jones",
        "givenName" => "Matt",
        "name" => "Jones, Matt",
        "nameIdentifiers" => [
          {
            "nameIdentifier" => "https://orcid.org/0000-0003-0077-4738",
            "nameIdentifierScheme" => "ORCID",
            "schemeUri" => "https://orcid.org",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [{ "title" => "R Interface to the DataONE REST API" }],
      )
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "https://cran.r-project.org"
        }
      )
    end

    it "from schema_org" do
      string = file_fixture("schema_org.json").read
      meta = subject.parse_xml(string)

      expect(meta["string"]).to eq(string)
      expect(meta["from"]).to eq("schema_org")
      expect(meta["doi"]).to eq("10.5438/4k3m-nyvg")
      expect(meta["creators"].length).to eq(1)
      expect(meta["creators"].first).to eq(
        "familyName" => "Fenner",
        "givenName" => "Martin",
        "name" => "Fenner, Martin",
        "nameIdentifiers" => [
          {
            "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
            "nameIdentifierScheme" => "ORCID",
            "schemeUri" => "https://orcid.org",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq([{ "title" => "Eating your own Dog Food" }])
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "DataCite"
        }
      )
    end

    it "from schema_org url" do
      string = "https://doi.pangaea.de/10.1594/PANGAEA.836178"
      meta = subject.parse_xml(string)

      expect(meta["string"]).to start_with("{\"@context\":\"http://schema.org")
      expect(meta["from"]).to eq("schema_org")
      expect(meta["doi"]).to eq("10.1594/pangaea.836178")
      expect(meta["creators"].length).to eq(8)
      expect(meta["creators"].first).to eq(
        "familyName" => "Johansson",
        "givenName" => "Emma",
        "name" => "Johansson, Emma",
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Hydrological and meteorological investigations in a lake near Kangerlussuaq, west Greenland",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "PANGAEA"
        }
      )
      expect(meta["schema_version"]).to eq(nil)
    end
  end

  context "update_xml" do
    # it "from schema 4" do
    #   string = file_fixture("datacite.xml").read
    #   subject = create(:doi, xml: string)

    #   # TODO
    #   # expect(subject.doi).to eq("10.14454/4k3m-nyvg")
    #   # expect(subject.creators).to eq([{"familyName"=>"Fenner", "givenName"=>"Martin", "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Fenner, Martin", "type"=>"Person"}])
    #   # expect(subject.titles).to eq([{"title"=>"Eating your own Dog Food"}])
    #   # expect(subject.publication).to eq("2016")
    #   # expect(meta["publisher"]).to eq("DataCite")
    # end

    it "from schema 3" do
      string = file_fixture("datacite_schema_3.xml").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.5061/dryad.8515")
      expect(meta["creators"].length).to eq(8)
      expect(meta["creators"].first).to eq(
        "familyName" => "Ollomo",
        "givenName" => "Benjamin",
        "name" => "Ollomo, Benjamin",
        "nameType" => "Personal",
        "nameIdentifiers" => [],
        "affiliation" => [],
      )
      expect(meta["titles"]).to eq(
        [{ "title" => "Data from: A new malaria agent in African hominids." }],
      )
      expect(meta["publication_year"]).to eq("2011")
      expect(meta["publisher"]).to eq(
        {
          "name" => "Dryad Digital Repository"
        }
      )
    end

    it "from schema 2.2" do
      string = file_fixture("datacite_schema_2.2.xml").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.14454/testpub")
      expect(meta["creators"]).to eq(
        [
          {
            "familyName" => "Smith",
            "givenName" => "John",
            "name" => "Smith, John",
            "nameType" => "Personal",
            "nameIdentifiers" => [],
            "affiliation" => [],
          },
          {
            "name" => "つまらないものですが",
            "nameIdentifiers" => [
              {
                "nameIdentifier" => "abc123", "nameIdentifierScheme" => "ISNI"
              },
            ],
            "affiliation" => [],
          },
        ],
      )
      expect(meta["titles"]).to eq(
        [
          { "title" => "Właściwości rzutowań podprzestrzeniowych" },
          {
            "title" => "Translation of Polish titles",
            "titleType" => "TranslatedTitle",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2010")
      expect(meta["publisher"]).to eq(
        {
          "name" => "Springer"
        }
      )
    end

    it "from schema 4 missing creators" do
      string = file_fixture("datacite_missing_creator.xml").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.5438/4k3m-nyvg")
      expect(meta["creators"]).to be_empty
      expect(meta["titles"]).to eq([{ "title" => "Eating your own Dog Food" }])
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "DataCite"
        }
      )
    end

    it "from crossref" do
      string = file_fixture("crossref.xml").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "affiliation" => [
          {
            "name" =>
              "Department of Plant Molecular Biology, University of Lausanne, Lausanne, Switzerland",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "eLife Sciences Publications, Ltd"
        }
      )
      expect(meta["container"]).to eq(
        "firstPage" => "e01567",
        "identifier" => "2050-084X",
        "identifierType" => "ISSN",
        "title" => "eLife",
        "type" => "Journal",
        "volume" => "3",
      )
    end

    it "from bibtex" do
      string = file_fixture("crossref.bib").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "{eLife} Sciences Organisation, Ltd."
        }
      )
      expect(meta["container"]).to eq(
        "identifier" => "2050-084X",
        "identifierType" => "ISSN",
        "title" => "eLife",
        "type" => "Journal",
        "volume" => "3",
      )
    end

    it "from ris" do
      string = file_fixture("crossref.ris").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.7554/elife.01567")
      expect(meta["creators"].length).to eq(5)
      expect(meta["creators"].first).to eq(
        "familyName" => "Sankar",
        "givenName" => "Martial",
        "name" => "Sankar, Martial",
        "nameType" => "Personal",
        "nameIdentifiers" => [],
        "affiliation" => [],
      )
      expect(meta["titles"]).to eq(
        [
          {
            "title" =>
              "Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth",
          },
        ],
      )
      expect(meta["publication_year"]).to eq("2014")
      expect(meta["publisher"]).to eq(
        {
          "name" => "(:unav)"
        }
      )
      expect(meta["container"]).to eq(
        "title" => "eLife", "type" => "Journal", "volume" => "3",
      )
    end

    it "from codemeta" do
      string = file_fixture("codemeta.json").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.5063/f1m61h5x")
      expect(meta["creators"].length).to eq(3)
      expect(meta["creators"].first).to eq(
        "affiliation" => [{ "name" => "NCEAS" }],
        "familyName" => "Jones",
        "givenName" => "Matt",
        "name" => "Jones, Matt",
        "nameIdentifiers" => [
          {
            "nameIdentifier" => "https://orcid.org/0000-0003-0077-4738",
            "nameIdentifierScheme" => "ORCID",
            "schemeUri" => "https://orcid.org",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq(
        [{ "title" => "R Interface to the DataONE REST API" }],
      )
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "https://cran.r-project.org"
        }
      )
    end

    it "from schema_org" do
      string = file_fixture("schema_org.json").read
      meta = subject.parse_xml(string)

      expect(meta["doi"]).to eq("10.5438/4k3m-nyvg")
      expect(meta["creators"].length).to eq(1)
      expect(meta["creators"].first).to eq(
        "familyName" => "Fenner",
        "givenName" => "Martin",
        "name" => "Fenner, Martin",
        "nameIdentifiers" => [
          {
            "nameIdentifier" => "https://orcid.org/0000-0003-1419-2405",
            "nameIdentifierScheme" => "ORCID",
            "schemeUri" => "https://orcid.org",
          },
        ],
        "nameType" => "Personal",
      )
      expect(meta["titles"]).to eq([{ "title" => "Eating your own Dog Food" }])
      expect(meta["publication_year"]).to eq("2016")
      expect(meta["publisher"]).to eq(
        {
          "name" => "DataCite"
        }
      )
    end
  end
end
