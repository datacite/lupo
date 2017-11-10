require 'rails_helper'

describe DoiSearch, type: :model, vcr: true do
  context "get_query_url" do
    it "default" do
      expect(DoiSearch.get_query_url).to eq("https://search.test.datacite.org/api?q=*%3A*&start=0&rows=25&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&fq=has_metadata%3Atrue+AND+is_active%3Atrue&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=minted+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&wt=json")
    end

    it "with rows" do
      expect(DoiSearch.get_query_url(rows: 50)).to eq("https://search.test.datacite.org/api?q=*%3A*&start=0&rows=50&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&fq=has_metadata%3Atrue+AND+is_active%3Atrue&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=minted+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&wt=json")
    end

    it "with q" do
      expect(DoiSearch.get_query_url(query: "cancer")).to eq("https://search.test.datacite.org/api?q=cancer&start=0&rows=25&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&fq=has_metadata%3Atrue+AND+is_active%3Atrue&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=score+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&wt=json")
    end

    it "with q sort by minted" do
      expect(DoiSearch.get_query_url(query: "cancer", sort: "minted")).to eq("https://search.test.datacite.org/api?q=cancer&start=0&rows=25&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&fq=has_metadata%3Atrue+AND+is_active%3Atrue&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=score+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&wt=json")
    end

    it "with id" do
      expect(DoiSearch.get_query_url(id: "10.5061/DRYAD.Q447C")).to eq("https://search.test.datacite.org/api?q=10.5061%2FDRYAD.Q447C&qf=doi&defType=edismax&wt=json")
    end

    it "with doi-id" do
      expect(DoiSearch.get_query_url("doi-id" => "10.5061/DRYAD.Q447C")).to eq("https://search.test.datacite.org/api?q=10.5061%2FDRYAD.Q447C&qf=doi&fl=doi%2CrelatedIdentifier&defType=edismax&wt=json")
    end

    it "with ids" do
      expect(DoiSearch.get_query_url(ids: "10.5061/DRYAD.Q447C/1,10.5061/DRYAD.Q447C/2,10.5061/DRYAD.Q447C/3")).to eq("https://search.test.datacite.org/api?q=+10.5061%2FDRYAD.Q447C%2F1+10.5061%2FDRYAD.Q447C%2F2+10.5061%2FDRYAD.Q447C%2F3&start=0&rows=3&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&qf=doi&fq=has_metadata%3Atrue+AND+is_active%3Atrue&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=minted+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&mm=1&wt=json")
    end

    it "with date created range" do
      expect(DoiSearch.get_query_url("until-created-date" => "2015")).to eq("https://search.test.datacite.org/api?q=*%3A*&start=0&rows=25&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cversion%2Cdatacentre_symbol%2Callocator_symbol%2Cschema_version%2Cxml%2Cmedia%2Cminted%2Cupdated&fq=has_metadata%3Atrue+AND+is_active%3Atrue+AND+minted%3A%5B*+TO+2015-12-31T23%3A59%3A59Z%5D&facet=true&facet.field=publicationYear&facet.field=datacentre_facet&facet.field=resourceType_facet&facet.field=schema_version&facet.limit=15&facet.mincount=1&sort=minted+desc&defType=edismax&bq=updated%3A%5BNOW%2FDAY-1YEAR+TO+NOW%2FDAY%5D&wt=json")
    end
  end

  context "normalize license" do
    it "cc0" do
      rights_uri = ["http://creativecommons.org/publicdomain/zero/1.0/"]
      expect(subject.normalize_license(rights_uri)).to eq("https://creativecommons.org/publicdomain/zero/1.0/")
    end

    it "cc-by" do
      rights_uri = ["https://creativecommons.org/licenses/by/4.0/"]
      expect(subject.normalize_license(rights_uri)).to eq("https://creativecommons.org/licenses/by/4.0/")
    end

    it "cc-by no trailing slash" do
      rights_uri = ["https://creativecommons.org/licenses/by/4.0"]
      expect(subject.normalize_license(rights_uri)).to eq("https://creativecommons.org/licenses/by/4.0/")
    end

    it "by-nc-nd" do
      rights_uri = ["https://creativecommons.org/licenses/by-nc-nd/4.0/"]
      expect(subject.normalize_license(rights_uri)).to eq("https://creativecommons.org/licenses/by-nc-nd/4.0/")
    end
  end

  it "dois" do
    dois = DoiSearch.where(rows: 60)
    expect(dois[:data].length).to eq(60)
    doi = dois[:data].last
    expect(DoiSearch.title).to eq("IMG_0134.jpg")
    expect(DoiSearch.resource_type.title).to eq("Dataset")
    meta = dois[:meta]
    expect(meta["resource-types"]).not_to be_empty
    expect(meta["years"]).not_to be_empty
    expect(meta).not_to be_empty
  end

  it "dois with query" do
    dois = DoiSearch.where(query: "cancer")
    expect(dois[:data].length).to eq(25)
    doi = dois[:data].first
    expect(DoiSearch.title).to eq("Cooking the Books: the Golem and the Ethics of Biotechnology")
    expect(DoiSearch.resource_type.title).to eq("Text")
  end

  it "dois with query sort by minted" do
    dois = DoiSearch.where(query: "cancer", sort: "minted")
    expect(dois[:data].length).to eq(25)
    doi = dois[:data].first
    expect(DoiSearch.title).to eq("Cooking the Books: the Golem and the Ethics of Biotechnology")
    expect(DoiSearch.resource_type.title).to eq("Text")
  end

  it "dois with query and resource-type-id" do
    dois = DoiSearch.where(query: "cancer", "resource-type-id" => "dataset")
    expect(dois[:data].length).to eq(3)
    doi = dois[:data].first
    expect(DoiSearch.title).to eq("Landings of European lobster (Homarus gammarus) and edible crab (Cancer pagurus) in 2011, Helgoland, North Sea")
    expect(DoiSearch.resource_type.title).to eq("Dataset")
  end

  it "dois with query and resource-type-id and data-center-id" do
    dois = DoiSearch.where(query: "cancer", "resource-type-id" => "dataset", "data-center-id" => "FIGSHARE.ARS")
    expect(dois[:data].length).to eq(25)
    doi = dois[:data].first
    expect(DoiSearch.title).to eq("Achilles_v3.3.7_README.txt")
    expect(DoiSearch.resource_type.title).to eq("Dataset")
  end

  it "doi" do
    doi = DoiSearch.where(id: "10.3886/ICPSR36357.V1")[:data]
    expect(DoiSearch.title).to eq("Arts and Cultural Production Satellite Account")
    expect(DoiSearch.resource_type.title).to eq("Dataset")
    expect(DoiSearch.data_center.title).to eq("ICPSR")
  end
end
