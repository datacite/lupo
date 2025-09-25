# frozen_string_literal: true

require "rails_helper"

describe Organization, type: :model, vcr: true do
  describe "ror_id_from_url" do
    it "full url" do
      ror_id = "https://ror.org/0521rfb23"
      expect(Organization.ror_id_from_url(ror_id)).to eq("ror.org/0521rfb23")
    end

    it "without https" do
      ror_id = "ror.org/0521rfb23"
      expect(Organization.ror_id_from_url(ror_id)).to eq("ror.org/0521rfb23")
    end

    it "without full path" do
      ror_id = "0521rfb23"
      expect(Organization.ror_id_from_url(ror_id)).to eq("ror.org/0521rfb23")
    end
  end

  describe "crossref_funder_id_from_url" do
    it "full url" do
      crossref_funder_id = "https://doi.org/10.13039/501100000780"
      expect(
        Organization.crossref_funder_id_from_url(crossref_funder_id),
      ).to eq("10.13039/501100000780")
    end

    it "without https" do
      crossref_funder_id = "doi.org/10.13039/501100000780"
      expect(
        Organization.crossref_funder_id_from_url(crossref_funder_id),
      ).to eq("10.13039/501100000780")
    end

    it "without full path" do
      crossref_funder_id = "10.13039/501100000780"
      expect(
        Organization.crossref_funder_id_from_url(crossref_funder_id),
      ).to eq("10.13039/501100000780")
    end

    it "without full path" do
      crossref_funder_id = "10.1038/501100000780"
      expect(
        Organization.crossref_funder_id_from_url(crossref_funder_id),
      ).to be_nil
    end
  end

  describe "grid_id_from_url" do
    it "full url" do
      grid_id = "https://grid.ac/institutes/grid.270680.b"
      expect(Organization.grid_id_from_url(grid_id)).to eq("grid.270680.b")
    end

    it "url without full path" do
      grid_id = "https://grid.ac/grid.270680.b"
      expect(Organization.grid_id_from_url(grid_id)).to eq("grid.270680.b")
    end

    it "without path" do
      grid_id = "grid.270680.b"
      expect(Organization.grid_id_from_url(grid_id)).to eq("grid.270680.b")
    end

    it "without https" do
      grid_id = "grid.ac/institutes/grid.270680.b"
      expect(Organization.grid_id_from_url(grid_id)).to eq("grid.270680.b")
    end
  end

  describe "find_by_id" do
    it "found" do
      id = "https://ror.org/0521rfb23"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/0521rfb23")
      expect(organization.name).to eq("Lincoln University - Pennsylvania")
      expect(organization.labels).to eq(
        [{"code"=>"EN", "name"=>"Lincoln University - Pennsylvania"},{ "code" => "ES", "name" => "Universidad Lincoln" }],
      )
      expect(organization.links).to eq(%w[http://www.lincoln.edu/])
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to eq("1854")
      expect(organization.geolocation).to eq(
        "latitude" => 39.808333333333, "longitude" => -75.927777777778,
      )
      expect(organization.ringgold).to eq("4558")
    end

    it "also found" do
      id = "https://ror.org/013meh722"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/013meh722")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.labels).to eq(
        [{ "code" => "CY", "name" => "Prifysgol Caergrawnt" }, {"code"=>"EN", "name"=>"University of Cambridge"}],
      )
      expect(organization.links).to eq(%w[https://www.cam.ac.uk])
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception_year).to eq("1209")
      expect(organization.geolocation).to eq(
        "latitude" => 52.205355979757925, "longitude" => 0.11315726963968827,
      )
      expect(organization.ringgold).to eq("2152")
    end

    it "found datacite member" do
      create(
        :provider,
          role_name: "ROLE_CONSORTIUM_ORGANIZATION",
          name: "University of Cambridge",
          symbol: "LPSW",
          ror_id: "https://ror.org/013meh722",
        )
      id = "https://ror.org/013meh722"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/013meh722")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.labels).to eq(
        [{ "code" => "CY", "name" => "Prifysgol Caergrawnt" },{"code"=>"EN", "name"=>"University of Cambridge"}],
      )
      expect(organization.links).to eq(%w[https://www.cam.ac.uk])
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception_year).to eq("1209")
      expect(organization.geolocation).to eq(
        "latitude" => 52.205355979757925, "longitude" => 0.11315726963968827,
      )
      expect(organization.ringgold).to eq("2152")
    end

    it "found funder" do
      id = "https://ror.org/018mejw64"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/018mejw64")
      expect(organization.name).to eq("Deutsche Forschungsgemeinschaft")
      expect(organization.labels).to eq(
        [{"code"=>"DE", "name"=>"Deutsche Forschungsgemeinschaft"},{ "code" => "EN", "name" => "German Research Foundation" }],
      )
      expect(organization.links).to eq(%w[http://www.dfg.de/en/])
      expect(organization.twitter).to eq("dfg_public")
      expect(organization.inception_year).to eq("1951")
      expect(organization.geolocation).to eq(
        "latitude" => 50.699443, "longitude" => 7.14777,
      )
      expect(organization.ringgold).to eq("39045")
    end

    it "found utf8" do
      id = "https://ror.org/02trn6p95"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/02trn6p95")
      expect(organization.name).to eq("Comisión Sectorial de Investigación Científica")
    end


    it "found no wikidata id" do
      id = "https://ror.org/02q0ygf45"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/02q0ygf45")
      expect(organization.name).to eq("OBS Medical (United Kingdom)")
      expect(organization.labels).to eq([{"name"=>"OBS Medical (United Kingdom)"}])
      expect(organization.links).to eq(%w[http://www.obsmedical.com/])
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to be_nil
      expect(organization.geolocation).to be_empty
      expect(organization.ringgold).to be_nil
    end

    it "not found in ror" do
      id = "https://doi.org/10.13039/100011105"
      organizations = Organization.find_by_id(id)
      expect(organizations[:data]).to be_nil
      expect(organizations[:errors]).to be_nil
    end
  end

  describe "find_by_grid_id" do
    it "found" do
      id = "https://grid.ac/institutes/grid.417434.1"
      organizations = Organization.find_by_grid_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/0521rfb23")
      expect(organization.name).to eq("Lincoln University - Pennsylvania")
      expect(organization.labels).to eq(
        [{"code"=>"EN", "name"=>"Lincoln University - Pennsylvania"},{ "code" => "ES", "name" => "Universidad Lincoln" }],
      )
      expect(organization.links).to eq(%w[http://www.lincoln.edu/])
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to eq("1854")
      expect(organization.geolocation).to eq(
        "latitude" => 39.808333333333, "longitude" => -75.927777777778,
      )
      expect(organization.ringgold).to eq("4558")
    end

    it "also found" do
      id = "https://grid.ac/institutes/grid.5335.0"
      organizations = Organization.find_by_grid_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/013meh722")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.labels).to eq(
        [{ "code" => "CY", "name" => "Prifysgol Caergrawnt" },{"code"=>"EN", "name"=>"University of Cambridge"}],
      )
      expect(organization.links).to eq(%w[https://www.cam.ac.uk])
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception_year).to eq("1209")
      expect(organization.geolocation).to eq(
        "latitude" => 52.205355979757925, "longitude" =>  0.11315726963968827,
      )
      expect(organization.ringgold).to eq("2152")
    end

    it "found funder" do
      id = "https://grid.ac/institutes/grid.424150.6"
      organizations = Organization.find_by_grid_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/018mejw64")
      expect(organization.name).to eq("Deutsche Forschungsgemeinschaft")
      expect(organization.labels).to eq(
        [{"code"=>"DE", "name"=>"Deutsche Forschungsgemeinschaft"},{ "code" => "EN", "name" => "German Research Foundation" }],
      )
      expect(organization.links).to eq(%w[http://www.dfg.de/en/])
      expect(organization.twitter).to eq("dfg_public")
      expect(organization.inception_year).to eq("1951")
      expect(organization.geolocation).to eq(
        "latitude" => 50.699443, "longitude" => 7.14777,
      )
      expect(organization.ringgold).to eq("39045")
    end

    it "found no wikidata id" do
      id = "https://grid.ac/institutes/grid.487335.e"
      organizations = Organization.find_by_grid_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/02q0ygf45")
      expect(organization.name).to eq("OBS Medical (United Kingdom)")
      expect(organization.labels).to eq([{"name"=>"OBS Medical (United Kingdom)"}])
      expect(organization.links).to eq(%w[http://www.obsmedical.com/])
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to be_nil
      expect(organization.geolocation).to be_empty
      expect(organization.ringgold).to be_nil
    end

    it "not found" do
      id = "https://grid.ac/institutes/xxx"
      organizations = Organization.find_by_grid_id(id)
      expect(organizations[:data]).to be_nil
      expect(organizations[:errors]).to be_nil
    end
  end

  describe "find_by_crossref_funder_id" do
    it "found" do
      id = "https://doi.org/10.13039/100007032"
      organizations = Organization.find_by_crossref_funder_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/0521rfb23")
      expect(organization.name).to eq("Lincoln University - Pennsylvania")
      expect(organization.labels).to eq(
        [{"code"=>"EN", "name"=>"Lincoln University - Pennsylvania"},{ "code" => "ES", "name" => "Universidad Lincoln" }],
      )
      expect(organization.links).to eq(%w[http://www.lincoln.edu/])
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to eq("1854")
      expect(organization.geolocation).to eq(
        "latitude" => 39.808333333333, "longitude" => -75.927777777778,
      )
      expect(organization.ringgold).to eq("4558")
    end

    it "also found" do
      id = "https://doi.org/10.13039/100010441"
      organizations = Organization.find_by_crossref_funder_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/013meh722")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.labels).to eq(
        [{ "code" => "CY", "name" => "Prifysgol Caergrawnt" },{"code"=>"EN", "name"=>"University of Cambridge"}],
      )
      expect(organization.links).to eq(%w[https://www.cam.ac.uk])
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception_year).to eq("1209")
      expect(organization.geolocation).to eq(
        "latitude" => 52.205355979757925, "longitude" => 0.11315726963968827,
      )
      expect(organization.ringgold).to eq("2152")
    end

    it "found funder" do
      id = "https://doi.org/10.13039/501100001659"
      organizations = Organization.find_by_crossref_funder_id(id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/018mejw64")
      expect(organization.name).to eq("Deutsche Forschungsgemeinschaft")
      expect(organization.labels).to eq(
        [{"code"=>"DE", "name"=>"Deutsche Forschungsgemeinschaft"},{ "code" => "EN", "name" => "German Research Foundation" }],
      )
      expect(organization.links).to eq(%w[http://www.dfg.de/en/])
      expect(organization.twitter).to eq("dfg_public")
      expect(organization.inception_year).to eq("1951")
      expect(organization.geolocation).to eq(
        "latitude" => 50.699443, "longitude" => 7.14777,
      )
      expect(organization.ringgold).to eq("39045")
    end

    it "not found" do
      id = "https://doi.org/10.13039/xxx"
      organizations = Organization.find_by_crossref_funder_id(id)
      expect(organizations[:data]).to be_nil
      expect(organizations[:errors]).to be_nil
    end
  end

  describe "find_by_wikidata_id" do
    it "found" do
      wikidata_id = "Q35794"
      organizations = Organization.find_by_wikidata_id(wikidata_id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("Q35794")
      expect(organization.name).to eq("University of Cambridge")
      expect(organization.twitter).to eq("Cambridge_Uni")
      expect(organization.inception_year).to eq("1209")
      expect(organization.geolocation).to eq(
        "latitude" => 52.205277777778, "longitude" => 0.11722222222222,
      )
      expect(organization.ringgold).to eq("2152")
    end

    it "found funder" do
      wikidata_id = "Q707283"
      organizations = Organization.find_by_wikidata_id(wikidata_id)
      expect(organizations[:data].size).to eq(1)
      organization = organizations[:data].first
      expect(organization.id).to eq("Q707283")
      expect(organization.name).to eq("German Research Foundation")
      expect(organization.twitter).to be_nil
      expect(organization.inception_year).to eq("1951")
      expect(organization.geolocation).to eq(
        "latitude" => 50.699443, "longitude" => 7.14777,
      )
      expect(organization.ringgold).to eq("39045")
    end
  end

  describe "query" do
    it "all" do
      query = nil
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(114_882)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/05cz4ke42")
      expect(organization.name).to eq("Wildwood Trust")
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(%w[https://wildwoodtrust.org/])
    end

    it "found" do
      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(12_386)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/04ps1r162")
      expect(organization.name).to eq("Lincoln University")
      expect(organization.labels).to eq(
        [{ "code" => "MI", "name" => "Te Whare Wanaka o Aoraki" }],
      )
      expect(organization.links).to eq(%w[https://www.lincoln.ac.nz])
    end

    it "found with umlaut" do
      query = "münster"
      organizations = Organization.query(query)
      expect(organizations.dig(:meta, "total")).to eq(13)
      expect(organizations[:data].size).to eq(13)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/042a1e381")
      expect(organization.name).to eq("Clemenshospital Münster")
      expect(organization.labels).to eq(
        [],
      )
      expect(organization.links).to eq(%w[https://www.clemenshospital.de/ch])
    end

    it "found page 2" do
      query = "lincoln university"
      organizations = Organization.query(query, offset: 2)
      expect(organizations.dig(:meta, "total")).to eq(12_386)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/02rdgsh90")
      expect(organization.name).to eq("Lincoln County Health Department")
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(%w[http://www.lincolncounty.org/index.aspx?NID=117])
    end

    it "found by types government" do
      organizations = Organization.query(nil, types: "government")
      expect(organizations.dig(:meta, "total")).to eq(7_574)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/045mrnd19")
      expect(organization.name).to eq("Government of Andhra Pradesh")
      expect(organization.types).to eq(%w[Government])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(%w[http://www.ap.gov.in/])
    end

    it "found by country gb" do
      organizations = Organization.query(nil, country: "gb")
      expect(organizations.dig(:meta, "total")).to eq(7_579)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/05cz4ke42")
      expect(organization.name).to eq("Wildwood Trust")
      expect(organization.types).to eq(%w[Nonprofit])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(%w[https://wildwoodtrust.org/])
    end

    it "found by types and country" do
      organizations =
        Organization.query(nil, types: "government", country: "gb")
      expect(organizations.dig(:meta, "total")).to eq(336)
      expect(organizations[:data].size).to eq(20)
      organization = organizations[:data].first
      expect(organization.id).to eq("https://ror.org/03bbh2s13")
      expect(organization.name).to eq(
        "Northumberland County Council",
      )
      expect(organization.types).to eq(%w[Government])
      expect(organization.labels).to eq([])
      expect(organization.links).to eq(
        %w[
          http://www.northumberland.gov.uk/Home.aspx
        ],
      )
    end

    it "not found" do
      query = "xxx"
      organizations = Organization.query(query)
      expect(organizations[:data]).to be_empty
    end

    it "status code not 200" do
      url =
        "https://api.ror.org/v2/organizations?query=lincoln%20university&page=1"
      stub = stub_request(:get, url).and_return(status: [408])

      query = "lincoln university"
      organizations = Organization.query(query)
      expect(organizations).to be_empty
      expect(stub).to have_been_requested
    end
  end
end
