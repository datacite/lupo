require 'rails_helper'

describe Repository, type: :model, vcr: true do
  describe "find_by_id" do
    it "found" do
      id = "https://doi.org/10.17616/r3qp53"
      repositories = Repository.find_by_id(id)
      expect(repositories[:data].size).to eq(1)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3qp53")
      expect(repository.re3data_id).to eq("r3d100010468")
      expect(repository.name).to eq("Zenodo")
      expect(repository.url).to eq("https://zenodo.org/")
      expect(repository.certificates).to eq([])
    end

    it "not found" do
      id = "https://doi.org/10.17616/xxxxx"
      repositories = Repository.find_by_id(id)
      expect(repositories[:data]).to be_nil
      expect(repositories[:errors]).to be_nil
    end
  end

  describe "query" do
    it "all" do
      query = nil
      repositories = Repository.query(query)
      expect(repositories.dig(:meta, "total")).to eq(1562)
      expect(repositories[:data].size).to eq(25)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3w05r")
      expect(repository.re3data_id).to eq("r3d100011565")
      expect(repository.name).to eq("1000 Functional Connectomes Project")
      expect(repository.url).to eq("http://fcon_1000.projects.nitrc.org/fcpClassic/FcpTable.html")
      expect(repository.certificates).to eq([])
    end

    it "found" do
      query = "climate"
      repositories = Repository.query(query)
      expect(repositories.dig(:meta, "total")).to eq(167)
      expect(repositories[:data].size).to eq(25)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3qd26")
      expect(repository.re3data_id).to eq("r3d100011691")
      expect(repository.name).to eq("ACTRIS Data Centre")
      expect(repository.url).to eq("http://actris.nilu.no/")
      expect(repository.certificates).to eq([])
    end

    it "pid" do
      repositories = Repository.query(nil, pid: true)
      expect(repositories.dig(:meta, "total")).to eq(651)
      expect(repositories[:data].size).to eq(25)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3vg6n")
      expect(repository.re3data_id).to eq("r3d100010216")
      expect(repository.name).to eq("4TU.Centre for Research Data")
      expect(repository.url).to eq("https://researchdata.4tu.nl/en/home/")
      expect(repository.pid_systems).to eq([{"text"=>"DOI"}])
    end

    it "certified" do
      repositories = Repository.query(nil, certified: true)
      expect(repositories.dig(:meta, "total")).to eq(154)
      expect(repositories[:data].size).to eq(25)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3vg6n")
      expect(repository.re3data_id).to eq("r3d100010216")
      expect(repository.name).to eq("4TU.Centre for Research Data")
      expect(repository.url).to eq("https://researchdata.4tu.nl/en/home/")
      expect(repository.certificates).to eq([{"text"=>"DSA"}])
    end

    it "open" do
      repositories = Repository.query(nil, open: true)
      expect(repositories.dig(:meta, "total")).to eq(1374)
      expect(repositories[:data].size).to eq(25)
      repository = repositories[:data].first
      expect(repository.id).to eq("https://doi.org/10.17616/r3w05r")
      expect(repository.re3data_id).to eq("r3d100011565")
      expect(repository.name).to eq("1000 Functional Connectomes Project")
      expect(repository.url).to eq("http://fcon_1000.projects.nitrc.org/fcpClassic/FcpTable.html")
      expect(repository.data_accesses).to eq([{"restrictions"=>[], "type"=>"open"}])
    end

    it "not found" do
      query = "xxx"
      repositories = Repository.query(query)
      expect(repositories[:data]).to be_empty
    end
  end
end
