# frozen_string_literal: true

require "rails_helper"

describe DataCatalog, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://doi.org/10.17616/r3qp53"
      data_catalogs = DataCatalog.find_by(id: id)
      expect(data_catalogs[:data].size).to eq(1)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3qp53")
      expect(data_catalog.re3data_id).to eq("r3d100010468")
      expect(data_catalog.name).to eq("Zenodo")
      expect(data_catalog.url).to eq("https://zenodo.org/")
      expect(data_catalog.certificates).to eq([])
    end

    it "not found" do
      id = "https://doi.org/10.17616/xxxxx"
      data_catalogs = DataCatalog.find_by(id: id)
      expect(data_catalogs[:data]).to be_nil
      expect(data_catalogs[:errors]).to be_nil
    end
  end

  describe "query" do
    it "all" do
      query = nil
      data_catalogs = DataCatalog.query(query)
      expect(data_catalogs.dig(:meta, "total")).to eq(1_723)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3w05r")
      expect(data_catalog.re3data_id).to eq("r3d100011565")
      expect(data_catalog.name).to eq("1000 Functional Connectomes Project")
      expect(data_catalog.url).to eq(
        "http://fcon_1000.projects.nitrc.org/fcpClassic/FcpTable.html",
      )
      expect(data_catalog.certificates).to eq([])
    end

    it "found" do
      query = "climate"
      data_catalogs = DataCatalog.query(query)
      expect(data_catalogs.dig(:meta, "total")).to eq(177)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3qd26")
      expect(data_catalog.re3data_id).to eq("r3d100011691")
      expect(data_catalog.name).to eq("ACTRIS Data Centre")
      expect(data_catalog.url).to eq("http://actris.nilu.no/")
      expect(data_catalog.certificates).to eq([])
    end

    it "found paginate" do
      query = "climate"
      data_catalogs = DataCatalog.query(query, offset: 2)
      expect(data_catalogs.dig(:meta, "total")).to eq(177)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3p32s")
      expect(data_catalog.re3data_id).to eq("r3d100010621")
      expect(data_catalog.name).to eq("CDC - Climate Data Center")
      expect(data_catalog.url).to eq(
        "https://cdc.dwd.de/catalogue/srv/en/main.home",
      )
      expect(data_catalog.certificates).to eq([{ "text" => "other" }])
    end

    it "pid" do
      data_catalogs = DataCatalog.query(nil, pid: true)
      expect(data_catalogs.dig(:meta, "total")).to eq(751)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3vg6n")
      expect(data_catalog.re3data_id).to eq("r3d100010216")
      expect(data_catalog.name).to eq("4TU.Centre for Research Data")
      expect(data_catalog.url).to eq("https://researchdata.4tu.nl/en/home/")
      expect(data_catalog.pid_systems).to eq([{ "text" => "DOI" }])
    end

    it "certified" do
      data_catalogs = DataCatalog.query(nil, certified: true)
      expect(data_catalogs.dig(:meta, "total")).to eq(169)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3vg6n")
      expect(data_catalog.re3data_id).to eq("r3d100010216")
      expect(data_catalog.name).to eq("4TU.Centre for Research Data")
      expect(data_catalog.url).to eq("https://researchdata.4tu.nl/en/home/")
      expect(data_catalog.certificates).to eq([{ "text" => "DSA" }])
    end

    it "open" do
      data_catalogs = DataCatalog.query(nil, open: true)
      expect(data_catalogs.dig(:meta, "total")).to eq(1_516)
      expect(data_catalogs[:data].size).to eq(25)
      data_catalog = data_catalogs[:data].first
      expect(data_catalog.id).to eq("https://doi.org/10.17616/r3w05r")
      expect(data_catalog.re3data_id).to eq("r3d100011565")
      expect(data_catalog.name).to eq("1000 Functional Connectomes Project")
      expect(data_catalog.url).to eq(
        "http://fcon_1000.projects.nitrc.org/fcpClassic/FcpTable.html",
      )
      expect(data_catalog.data_accesses).to eq(
        [{ "restrictions" => [], "type" => "open" }],
      )
    end

    it "not found" do
      query = "xxx"
      data_catalogs = DataCatalog.query(query)
      expect(data_catalogs[:data]).to be_empty
    end
  end
end
