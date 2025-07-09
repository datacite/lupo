# frozen_string_literal: true

require "rails_helper"

def import_index(index_class)
  index_class.import
  index_class.__elasticsearch__.client.indices.refresh(index: index_class.index_name)
end

def clear_index(index_class)
  index_class.__elasticsearch__.client.delete_by_query(index: index_class.index_name, body: { query: { match_all: {} } })
  index_class.__elasticsearch__.client.indices.refresh(index: index_class.index_name)
end

def reset_indices
  clear_index(DataciteDoi)
  clear_index(Client)
  clear_index(Provider)
  import_index(Provider)
  import_index(Client)
  import_index(DataciteDoi)
end

describe RepositoriesController, type: :request, elasticsearch: true do
  let(:ids) { clients.map(&:uid).join(",") }
  let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let!(:provider) do
    create(
      :provider,
      consortium: consortium,
      symbol: "ABC",
      role_name: "ROLE_CONSORTIUM_ORGANIZATION",
      password_input: "12345",
    )
  end
  let!(:client) do
    create(:client, provider: provider, client_type: "repository")
  end
  let(:bearer) do
    User.generate_token(
      role_id: "provider_admin", provider_id: provider.uid,
    )
  end
  let(:consortium_bearer) do
    User.generate_token(
      role_id: "consortium_admin", provider_id: consortium.uid,
    )
  end
  let(:params) do
    {
      "data" => {
        "type" => "clients",
        "attributes" => {
          "symbol" => provider.symbol + ".IMPERIAL",
          "name" => "Imperial College",
          "systemEmail" => "bob@example.com",
          "salesforceId" => "abc012345678901234",
          "software" => "MyCoRe",
          "fromSalesforce" => true,
          "clientType" => "repository",
          "certificate" => %w[CoreTrustSeal],
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
  let(:consortium_headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer " + consortium_bearer,
    }
  end
  let(:query) { "jamon" }

  describe "GET /repositories", elasticsearch: false, prefix_pool_size: 4 do
    let!(:clients) { create_list(:client, 3) }

    before do
      reset_indices
    end

    it "returns repositories" do
      get "/repositories", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(4)
      expect(json.dig("meta", "providers").length).to eq(4)
      expect(json.dig("meta", "providers").first).to eq(
        "count" => 1,
        "id" => provider.uid,
        "title" => "My provider",
      )
    end
  end

  describe "GET /repositories/:id" do
    context "when the record exists" do
      it "returns the repository" do
        get "/repositories/#{client.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(client.name)
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "bc7d0274-3472-4a79-b631-e4c7baccc667",
        )
        expect(json.dig("data", "attributes", "software")).to eq(client.software)
        # Newly created repositories will have 1 prefix.
        expect(json["meta"]).to eq("doiCount" => 0, "prefixCount" => 1)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/repositories/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end

    context "when has analytics fields" do
      # Create a client with analytics fields
      let!(:client) do
        create(
          :client,
          provider: provider,
          client_type: "repository",
          analytics_dashboard_url: "example.com/dashboard",
          analytics_tracking_id: "example.com",
        )
      end

      it "returns analytics fields" do
        get "/repositories/#{client.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "analyticsDashboardUrl")).to eq("example.com/dashboard")
        expect(json.dig("data", "attributes", "analyticsTrackingId")).to eq("example.com")
      end

      it "when anonymous, returns nil for analytics fields" do
        get "/repositories/#{client.uid}", nil

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "analyticsDashboardUrl")).to eq(nil)
        expect(json.dig("data", "attributes", "analyticsTrackingId")).to eq(nil)
      end
    end
  end

  describe "GET /repositories/totals", elasticsearch: false, prefix_pool_size: 2 do
    let(:client) { create(:client) }
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end

    before do
      reset_indices
    end

    it "returns repositories" do
      get "/repositories/totals", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.first.dig("count")).to eq(3)
      expect(json.first.dig("states")).to eq(
        [{ "count" => 3, "id" => "findable", "title" => "Findable" }],
      )
      expect(json.first.dig("temporal")).not_to be_nil
    end
  end

  describe "GET /repositories/:id meta", elasticsearch: false, prefix_pool_size: 2 do
    let(:provider) { create(:provider) }
    let(:client) { create(:client) }
    # Do not need to create a client_prefix since the prefix is auto-assigned at repository creation.
    # let!(:client_prefix) { create(:client_prefix, client: client) }
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end

    before do
      reset_indices
    end

    it "returns repository" do
      get "/repositories/#{client.uid}"

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "name")).to eq(client.name)
      expect(json["meta"]).to eq("doiCount" => 3, "prefixCount" => 1)
    end
  end

  describe "GET /repositories/:id/stats", elasticsearch: false, prefix_pool_size: 2 do
    let(:provider) { create(:provider) }
    let(:client) { create(:client) }
    let!(:datacite_dois) do
      create_list(
        :doi,
        3,
        client: client, aasm_state: "findable", type: "DataciteDoi",
      )
    end

    before do
      reset_indices
    end

    it "returns repository" do
      get "/repositories/#{client.uid}/stats"

      current_year = Date.today.year.to_s
      expect(last_response.status).to eq(200)
      expect(json["resourceTypes"]).to eq(
        [{ "count" => 3, "id" => "dataset", "title" => "Dataset" }],
      )
      expect(json["dois"]).to eq(
        [{ "count" => 3, "id" => current_year, "title" => current_year }],
      )
    end
  end

  describe "POST /repositories" do
    context "when the request is valid" do
      it "creates a repository" do
        post "/repositories", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["systemEmail"]).to eq("bob@example.com")
        expect(attributes["certificate"]).to eq(%w[CoreTrustSeal])
        expect(attributes["software"]).to eq("MyCoRe")
        expect(attributes["salesforceId"]).to eq("abc012345678901234")

        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )
      end

      it "from salesforce" do
        post "/repositories", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["fromSalesforce"]).to eq(true)

        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )
      end
    end

    context "consortium" do
      it "creates a repository" do
        post "/repositories", params, consortium_headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Imperial College")
        expect(attributes["systemEmail"]).to eq("bob@example.com")
        expect(attributes["certificate"]).to eq(%w[CoreTrustSeal])
        expect(attributes["salesforceId"]).to eq("abc012345678901234")

        relationships = json.dig("data", "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )
      end
    end

    context "when the request is invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "symbol" => provider.symbol + ".IMPERIAL",
              "name" => "Imperial College",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider.uid },
              },
            },
          },
        }
      end

      it "returns status code 422" do
        post "/repositories", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq(
          [
            { "source" => "system_email", "title" => "Can't be blank", "uid" => "#{provider.uid}.imperial" },
          ],
        )
      end
    end
  end

  describe "PUT /repositories/:id" do
    context "when the record exists" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "name" => "Imperial College 2",
              "clientType" => "periodical",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
              "software" => "OPUS"
            },
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Imperial College 2",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
        expect(json.dig("data", "attributes", "software")).to eq(
          "OPUS",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
        expect(json.dig("data", "attributes", "clientType")).to eq("periodical")
      end
    end

    context "consortium" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "name" => "Imperial College 2",
              "clientType" => "periodical",
              "globusUuid" => "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
            },
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}",
            params, consortium_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Imperial College 2",
        )
        expect(json.dig("data", "attributes", "globusUuid")).to eq(
          "9908a164-1e4f-4c17-ae1b-cc318839d6c8",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
        expect(json.dig("data", "attributes", "clientType")).to eq("periodical")
      end
    end

    context "removes the globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories", "attributes" => { "globusUuid" => nil }
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("My data center")
        expect(json.dig("data", "attributes", "globusUuid")).to be_nil
      end
    end

    context "update subjects" do
      let(:subjects) do
        [{ "subject" => "80505 Web Technologies (excl. Web Search)",
           "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
           "subjectScheme" => "FOR",
           "lang" => "en",
           "valueUri" => nil,
           "classificationCode" => "001" }]
      end
      let(:update_attributes) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "subjects" => subjects,
              "repositoryType" => "disciplinary",
            },
          },
        }
      end

      let(:empty_subject_attributes) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "subjects" => nil,
            },
          },
        }
      end

      it "updates the repository" do
        put "/repositories/#{client.symbol}", update_attributes, headers
        expect(json.dig("data", "attributes", "subjects")).to eq([
          { "lang" => "en",
            "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
            "subject" => "80505 Web Technologies (excl. Web Search)",
            "subjectScheme" => "FOR",
            "valueUri" => nil,
            "classificationCode" => "001"
          }
        ])
      end

      it "updates the repository when lang is nil" do
        subjects.first["lang"] = nil
        put "/repositories/#{client.symbol}", update_attributes, headers
        expect(json.dig("data", "attributes", "subjects")).to eq([
          { "lang" => nil,
            "schemeUri" => "http://www.abs.gov.au/ausstats/abs@.nsf/0/6BB427AB9696C225CA2574180004463E",
            "subject" => "80505 Web Technologies (excl. Web Search)",
            "subjectScheme" => "FOR",
            "valueUri" => nil,
            "classificationCode" => "001"
          }
        ])
      end

      it "accepts an empty array" do
        put "/repositories/#{client.symbol}", empty_subject_attributes, headers
        expect(json.dig("data", "attributes", "subjects")).to match_array([])
      end
    end


    context "transfer repository" do
      let(:bearer) { User.generate_token }
      let(:staff_headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Bearer " + bearer,
        }
      end

      let(:new_provider) do
        create(:provider, symbol: "QUECHUA", password_input: "12345")
      end
      let(:prefix) { client.prefixes.first }
      let(:doi) { create_list(:doi, 10, client: client) }

      let(:params) do
        {
          "data" => {
            "type" => "clients",
            "attributes" => {
              "mode" => "transfer", "targetId" => new_provider.symbol
            },
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}",
            params, staff_headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq("My data center")
        expect(
          json.dig("data", "relationships", "provider", "data", "id"),
        ).to eq("quechua")
        expect(
          json.dig("data", "relationships", "prefixes", "data").first.dig("id"),
        ).to eq(prefix.uid)

        get "/providers/#{provider.symbol}"

        expect(
          json.dig("data", "relationships", "prefixes", "data"),
        ).to be_empty

        get "/providers/#{new_provider.symbol}"

        expect(
          json.dig("data", "relationships", "prefixes", "data").first.dig("id"),
        ).to eq(new_provider.prefixes.first.uid)

        get "/prefixes/#{prefix.uid}"
        expect(
          json.dig("data", "relationships", "clients", "data").first.dig("id"),
        ).to eq(client.uid)
      end
    end

    context "invalid globus_uuid" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories", "attributes" => { "globusUuid" => "abc" }
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "globus_uuid", "title" => "Abc is not a valid UUID",
          "uid" => client.uid
        )
      end
    end

    context "using basic auth", vcr: true do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => { "name" => "Imperial College 2" },
          },
        }
      end
      let(:credentials) do
        provider.encode_auth_param(
          username: provider.uid, password: "12345",
        )
      end
      let(:headers) do
        {
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Basic " + credentials,
        }
      end

      xit "updates the record" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Imperial College 2",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
      end
    end

    context "updating with ISSNs" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "name" => "Journal of Insignificant Results",
              "clientType" => "periodical",
              "issn" => { "electronic" => "1544-9173", "print" => "1545-7885" },
            },
          },
        }
      end

      it "updates the record" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(
          "Journal of Insignificant Results",
        )
        expect(json.dig("data", "attributes", "name")).not_to eq(client.name)
        expect(json.dig("data", "attributes", "clientType")).to eq("periodical")
        expect(json.dig("data", "attributes", "issn")).to eq(
          "electronic" => "1544-9173", "print" => "1545-7885",
        )
      end
    end

    context "when the request is invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "repositories",
            "attributes" => {
              "symbol" => client.symbol + "M",
              "email" => "bob@example.com",
              "name" => "Imperial College",
            },
          },
        }
      end

      it "returns status code 422" do
        put "/repositories/#{client.symbol}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "symbol", "title" => "Cannot be changed",
          "uid" => client.uid + "m"
        )
      end
    end
  end

  describe "DELETE /repositories/:id" do
    it "returns status code 204" do
      delete "/repositories/#{client.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end

    it "returns status code 204 with consortium" do
      delete "/repositories/#{client.uid}",
             nil, consortium_headers

      expect(last_response.status).to eq(204)
    end

    context "when the resource doesnt exist" do
      it "returns status code 404" do
        delete "/repositories/xxx", nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/repositories/xxx", nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "doi transfer", elasticsearch: true do
    let!(:dois) { create_list(:doi, 3, client: client) }
    let(:target) do
      create(
        :client,
        provider: provider,
        symbol: provider.symbol + ".TARGET",
        name: "Target Client",
      )
    end
    let(:params) do
      {
        "data" => {
          "type" => "repositories",
          "attributes" => { "targetId" => target.symbol },
        },
      }
    end

    before do
      DataciteDoi.import
      sleep 2
    end

    it "transfered all DOIs" do
      put "/repositories/#{client.symbol}", params, headers
      sleep 1

      expect(last_response.status).to eq(200)
    end

    it "transfered all DOIs consortium" do
      put "/repositories/#{client.symbol}",
          params, consortium_headers
      sleep 1

      expect(last_response.status).to eq(200)
    end
  end
end
