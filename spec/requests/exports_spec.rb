# frozen_string_literal: true

require "rails_helper"

describe ExportsController, type: :request do
  let(:admin_bearer) { User.generate_token }
  let(:admin_headers) do
    {
      "HTTP_ACCEPT" => "text/csv",
      "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer,
    }
  end

  let(:consortium) do
    create(
      :provider,
      role_name: "ROLE_CONSORTIUM",
      name: "Virtual Library of Virginia",
      symbol: "VIVA",
    )
  end
  let!(:provider) do
    create(
      :provider,
      role_name: "ROLE_CONSORTIUM_ORGANIZATION",
      name: "University of Virginia",
      symbol: "UVA",
      consortium: consortium,
    )
  end

  describe "GET /export/organizations", elasticsearch: true do
    before do
      Provider.import
      sleep 2
    end

    it "returns organizations", vcr: false do
      get "/export/organizations", nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(3)
      expect(csv[0]).to start_with(
        "Name,fabricaAccountId,Parent Organization,Is Active",
      )
      expect(csv[1]).to start_with("Virtual Library of Virginia,VIVA,,true")
      expect(csv[2]).to start_with("University of Virginia,UVA,VIVA,true")
    end

    it "returns organizations from date", vcr: false do
      get "/export/organizations?from-date=#{Date.today}",
          nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(3)
      expect(csv[0]).to start_with(
        "Name,fabricaAccountId,Parent Organization,Is Active",
      )
      expect(csv[1]).to start_with("Virtual Library of Virginia,VIVA,,true")
      expect(csv[2]).to start_with("University of Virginia,UVA,VIVA,true")
    end
  end

  describe "GET /export/repositories", elasticsearch: true do
    let(:client) do
      create(
        :client,
        provider: provider,
        symbol: "UVA.LIBRARY",
        name: "University of Virginia Library",
      )
    end
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

    before do
      DataciteDoi.import
      Client.import
      sleep 2
    end

    it "returns repositories", vcr: false do
      get "/export/repositories", nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(2)
      expect(csv[0]).to start_with(
        "Repository Name,Repository ID,Organization,isActive",
      )
      expect(csv[1]).to start_with(
        "University of Virginia Library,UVA.LIBRARY,UVA,true",
      )
      dois_total = csv[1].strip.split(",")[15].to_i
      expect(dois_total).to eq(3)
      dois_missing = csv[1].strip.split(",")[18].to_i
      expect(dois_missing).to eq(0)
    end

    it "returns repositories from date", vcr: false do
      get "/export/repositories?from-date=#{Date.today}",
          nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(2)
      expect(csv[0]).to start_with(
        "Repository Name,Repository ID,Organization,isActive",
      )
      expect(csv[1]).to start_with(
        "University of Virginia Library,UVA.LIBRARY,UVA,true",
      )
      dois_total = csv[1].strip.split(",")[15].to_i
      expect(dois_total).to eq(3)
      dois_missing = csv[1].strip.split(",")[18].to_i
      expect(dois_missing).to eq(0)
    end
  end

  describe "GET /export/contacts", elasticsearch: true do
    before do
      Provider.import
      sleep 2
    end

    it "returns all contacts", vcr: false do
      get "/export/contacts", nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(9)
      expect(csv[0]).to eq(
        "fabricaAccountId,fabricaId,email,firstName,lastName,type\n",
      )
      expect(csv[1]).to start_with(
        "VIVA,VIVA-kristian@example.com,kristian@example.com,Kristian,Garza,technical;secondaryTechnical",
      )
      expect(csv[2]).to start_with(
        "VIVA,VIVA-martin@example.com,martin@example.com,Martin,Fenner,service;secondaryService",
      )
      expect(csv[3]).to start_with(
        "VIVA,VIVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
      expect(csv[4]).to start_with(
        "VIVA,VIVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
      expect(csv[5]).to start_with(
        "UVA,UVA-kristian@example.com,kristian@example.com,Kristian,Garza,technical;secondaryTechnical",
      )
      expect(csv[6]).to start_with(
        "UVA,UVA-martin@example.com,martin@example.com,Martin,Fenner,service;secondaryService",
      )
      expect(csv[7]).to start_with(
        "UVA,UVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
      expect(csv[8]).to start_with(
        "UVA,UVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
    end

    it "returns all contacts from date", vcr: false do
      get "/export/contacts?from-date=#{Date.today}",
          nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(9)
      expect(csv[0]).to eq(
        "fabricaAccountId,fabricaId,email,firstName,lastName,type\n",
      )
      expect(csv[1]).to start_with(
        "VIVA,VIVA-kristian@example.com,kristian@example.com,Kristian,Garza,technical;secondaryTechnical",
      )
      expect(csv[2]).to start_with(
        "VIVA,VIVA-martin@example.com,martin@example.com,Martin,Fenner,service;secondaryService",
      )
      expect(csv[3]).to start_with(
        "VIVA,VIVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
      expect(csv[4]).to start_with(
        "VIVA,VIVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
      expect(csv[5]).to start_with(
        "UVA,UVA-kristian@example.com,kristian@example.com,Kristian,Garza,technical;secondaryTechnical",
      )
      expect(csv[6]).to start_with(
        "UVA,UVA-martin@example.com,martin@example.com,Martin,Fenner,service;secondaryService",
      )
      expect(csv[7]).to start_with(
        "UVA,UVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
      expect(csv[8]).to start_with(
        "UVA,UVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
    end

    it "returns voting contacts", vcr: false do
      get "/export/contacts?type=voting", nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(3)
      expect(csv[0]).to eq(
        "fabricaAccountId,fabricaId,email,firstName,lastName,type\n",
      )
      expect(csv[1]).to start_with(
        "VIVA,VIVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
      expect(csv[2]).to start_with(
        "UVA,UVA-robin@example.com,robin@example.com,Robin,Dasler,voting",
      )
    end

    it "returns billing contacts", vcr: false do
      get "/export/contacts?type=billing", nil, admin_headers

      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(3)
      expect(csv[0]).to eq(
        "fabricaAccountId,fabricaId,email,firstName,lastName,type\n",
      )
      expect(csv[1]).to start_with(
        "VIVA,VIVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
      expect(csv[2]).to start_with(
        "UVA,UVA-trisha@example.com,trisha@example.com,Trisha,Cruse,billing;secondaryBilling",
      )
    end
  end

  describe "GET /export/check-indexed-dois", elasticsearch: true do
    let(:client) do
      create(
        :client,
        provider: provider,
        symbol: "UVA.LIBRARY",
        name: "University of Virginia Library",
      )
    end
    let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

    before do
      DataciteDoi.import
      Client.import
      sleep 2
    end

    it "returns repositories with dois not indexed", vcr: false do
      get "/export/check-indexed-dois",
          nil, admin_headers
      puts last_response.body
      expect(last_response.status).to eq(200)
      csv = last_response.body.lines
      expect(csv.length).to eq(1)
      expect(csv[0].strip).to be_blank
    end
  end
end
