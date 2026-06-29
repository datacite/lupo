# frozen_string_literal: true

require "rails_helper"

describe WorksController, type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) do
    Client.generate_token(
      role_id: "staff_admin", uid: admin.symbol, password: admin.password,
    )
  end
  let(:admin_headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer,
    }
  end

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) do
    create(
      :client,
      provider: provider,
      symbol: ENV["MDS_USERNAME"],
      password: ENV["MDS_PASSWORD"],
    )
  end
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) do
    create(:client_prefix, client: client, prefix: prefix)
  end
  let(:bearer) do
    Client.generate_token(
      role_id: "client_admin",
      uid: client.symbol,
      provider_id: provider.symbol.downcase,
      client_id: client.symbol.downcase,
      password: client.password,
    )
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + bearer,
    }
  end

  describe "GET /works", elasticsearch: true do
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, event: "publish", type: "DataciteDoi",
      )
    end

    before do
      DataciteDoi.import
      sleep 2
    end

    it "returns works" do
      travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
        get "/works"

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(3)
        expect(json.dig("meta", "total")).to eq(3)
        expect_legacy_sunset_headers
      end
    end
  end

  describe "GET /works/:id" do
    let!(:datacite_doi) do
      create(:doi, client: client, event: "publish", type: "DataciteDoi")
    end

    context "when the record exists" do
      it "returns the work" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/works/#{datacite_doi.doi}"

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq(
            datacite_doi.doi.downcase,
          )
          expect(json.dig("data", "attributes", "author").length).to eq(8)
          expect(json.dig("data", "attributes", "author").first).to eq(
            "family" => "Ollomo", "given" => "Benjamin",
          )
          expect(json.dig("data", "attributes", "title")).to eq(
            "Data from: A new malaria agent in African hominids.",
          )
          expect(json.dig("data", "attributes", "description")).to eq(
            "Data from: A new malaria agent in African hominids.",
          )
          expect(json.dig("data", "attributes", "container-title")).to eq(
            "Dryad Digital Repository",
          )
          expect(json.dig("data", "attributes", "published")).to eq("2011")
          expect_legacy_sunset_headers
        end
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/works/10.5256/xxxx", nil, headers

          expect(last_response.status).to eq(404)
          expect(json).to eq(
            "errors" => [
              {
                "status" => "404",
                "title" => "The resource you are looking for doesn't exist.",
              },
            ],
          )
          expect_legacy_sunset_headers
        end
      end
    end

    context "draft doi" do
      let!(:datacite_doi) { create(:doi, client: client, type: "DataciteDoi") }

      it "returns 404 status" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/works/#{datacite_doi.doi}", nil, headers

          expect(last_response.status).to eq(404)
          expect(json).to eq(
            "errors" => [
              {
                "status" => "404",
                "title" => "The resource you are looking for doesn't exist.",
              },
            ],
          )
          expect_legacy_sunset_headers
        end
      end
    end

    context "anonymous user" do
      it "returns the Doi" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/works/#{datacite_doi.doi}"

          expect(last_response.status).to eq(200)
          expect(json.dig("data", "attributes", "doi")).to eq(
            datacite_doi.doi.downcase,
          )
          expect_legacy_sunset_headers
        end
      end
    end

    context "anonymous user draft doi" do
      let!(:datacite_doi) { create(:doi, client: client, type: "DataciteDoi") }

      it "returns 404 status" do
        travel_to Time.utc(2026, 6, 30, 12, 0, 0) do
          get "/works/#{datacite_doi.doi}"

          expect(last_response.status).to eq(404)
          expect(json).to eq(
            "errors" => [
              {
                "status" => "404",
                "title" => "The resource you are looking for doesn't exist.",
              },
            ],
          )
          expect_legacy_sunset_headers
        end
      end
    end
  end

  describe "after legacy sunset date" do
    let!(:datacite_doi) do
      create(:doi, client: client, event: "publish", type: "DataciteDoi")
    end

    around do |example|
      travel_to(Time.utc(2026, 7, 1, 0, 0, 0)) { example.run }
    end

    it "returns 410 for GET /works" do
      get "/works"

      expect(last_response.status).to eq(410)
      expect(json["errors"].first).to include(
        "status" => "410",
        "title" => "This endpoint has been deprecated and is no longer available.",
        "detail" => "Use GET /dois instead of GET /works.",
      )
      expect(last_response.headers["Sunset"]).to be_nil
      expect(last_response.headers["Link"]).to include('rel="sunset"')
    end

    it "returns 410 for GET /works/:id" do
      get "/works/#{datacite_doi.doi}"

      expect(last_response.status).to eq(410)
      expect(json["errors"].first).to include(
        "status" => "410",
        "detail" => "Use GET /dois instead of GET /works/#{datacite_doi.doi}.",
      )
    end

    it "does not affect GET /dois" do
      get "/dois/#{datacite_doi.doi}"

      expect(last_response.status).to eq(200)
      expect_no_legacy_sunset_header
    end
  end
end
