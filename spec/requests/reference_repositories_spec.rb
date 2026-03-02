# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe ReferenceRepositoriesController, type: :request, elasticsearch: true do
  let(:ids) { clients.map(&:uid).join(",") }
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
  let(:provider_member_only) { create(:provider, role_name: "ROLE_MEMBER", symbol: "YYYY", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let!(:client) { create(:client, provider: provider) }
  let(:params) do
    {
      "data" => {
        "type" => "clients",
        "attributes" => {
          "symbol" => provider.symbol + ".IMPERIAL",
          "name" => "Imperial College",
          "contactEmail" => "bob@example.com",
          "clientType" => "repository",
        },
        "relationships": {
          "provider": {
            "data": { "type": "providers", "id": provider.uid },
          },
        },
      },
    }
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end
  let(:query) { "jamon" }

  before :all do
    VCR.use_cassette("ReferenceRepositoryType/re3Data/set_of_10_re3_repositories") do
      create(:prefix, uid: "10.17616")
      @ref_repo = create(:reference_repository, re3doi:  "10.17616/R3BW5R")
      create(:reference_repository, re3doi:  "10.17616/r3vg6n")
      create(:reference_repository, re3doi:  "10.17616/r37m1j")
      create(:reference_repository, re3doi:  "10.17616/R3003X")
      create(:reference_repository, re3doi:  "10.17616/R31NJCHT")
      create(:reference_repository, re3doi:  "10.17616/R3NC74")
      create(:reference_repository, re3doi:  "10.17616/R3106C")
      create(:reference_repository, re3doi:  "10.17616/R31NJN59")
      create(:reference_repository, re3doi:  "10.17616/R31NJMTE")
      @client = create(:client, re3data_id:  "10.17616/R31NJMJX")
      ReferenceRepository.import(force: true)
      sleep 2
    end
  end

  after :all do
    ReferenceRepository.destroy_all
    Client.destroy_all
    Provider.destroy_all
    Prefix.destroy_all
  end

  describe "GET /reference-repositories", elasticsearch: true do
    let!(:clients) { create_list(:client, 3) }

    before do
      Client.import()
      ReferenceRepository.import()
      sleep 3
    end
    it "returns reference-repositories" do
      get "/reference-repositories", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(14)
      expect(json.dig("meta", "total")).to eq(14)
    end
  end

  describe "GET /reference-repositories/:id" do
    context "when the record exists" do
      it "returns the repository" do
        get "/reference-repositories/#{@ref_repo.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("UCLA Social Science Data Archive Dataverse")
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/reference-repositories/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end
end
