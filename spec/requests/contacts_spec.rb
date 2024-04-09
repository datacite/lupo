# frozen_string_literal: true

require "rails_helper"

describe ContactsController, type: :request, elasticsearch: true do
  let(:consortium) { create(:provider, role_name: "ROLE_CONSORTIUM") }
  let(:provider) do
    create(
      :provider,
      consortium: consortium,
      symbol: "ABC",
      role_name: "ROLE_CONSORTIUM_ORGANIZATION",
      password_input: "12345",
    )
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
  let!(:service_contact) { create(:contact, provider: provider, role_name: ["service"]) }
  let!(:contact) { create(:contact, provider: provider, role_name: ["billing"]) }
  let(:params) do
    {
      "data" => {
        "type" => "contacts",
        "attributes" => {
          "givenName" => "Josiah",
          "familyName" => "Carberry",
          "email" => "bob@example.com",
          "roleName" => ["voting"],
          "fromSalesforce" => true
        },
        "relationships": {
          "provider": {
            "data": { "type": "providers", "id": provider.uid },
          }
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

  describe "GET /contacts", elasticsearch: true do
    let!(:contacts) { create_list(:contact, 3) }

    before do
      Contact.import
      sleep 1
    end

    it "returns contacts" do
      get "/contacts", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta")).to eq("page" => 1, "roles" => [{ "count" => 3, "id" => "voting", "title" => "Voting" }, { "count" => 1, "id" => "billing", "title" => "Billing" }, { "count" => 1, "id" => "service", "title" => "Service" }], "total" => 5, "totalPages" => 1)
    end
  end

  describe "GET /contacts query" do
    let!(:contacts) { create_list(:contact, 3) }

    before do
      Contact.import
      sleep 2
    end

    it "returns contacts" do
      get "/contacts?query=carberry", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(5)
    end
  end

  describe "GET /contacts query role_name" do
    let!(:contacts) { create_list(:contact, 3) }

    before do
      Contact.import
      sleep 1
    end

    it "returns contacts" do
      get "/contacts?role-name=billing", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(1)
      expect(json.dig("meta", "total")).to eq(1)
    end
  end

  describe "GET /contacts by provider" do
    let!(:contacts) { create_list(:contact, 3, provider: provider) }

    before do
      Provider.import
      Contact.import
      sleep 2
    end

    it "returns contacts" do
      get "/contacts?provider-id=#{provider.uid}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(5)
      expect(json.dig("meta", "total")).to eq(5)
    end
  end

  describe "GET /contacts by consortium" do
    let!(:consortium_contact) { create(:contact, provider: consortium, role_name: ["billing"]) }

    before do
      Provider.import
      Contact.import
      sleep 1
    end

    it "returns contacts" do
      get "/contacts?consortium-id=#{consortium.uid}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(3)
      expect(json.dig("meta", "total")).to eq(3)
    end
  end

  describe "GET /contacts exclude deleted" do
    let!(:contacts) { create_list(:contact, 3, deleted_at: Time.zone.now) }

    before do
      Contact.import
      sleep 2
    end

    it "returns contacts" do
      get "/contacts", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(2)
      expect(json.dig("meta", "total")).to eq(2)
    end
  end

  describe "GET /contacts/:id" do
    context "when the record exists" do
      it "returns the contact" do
        get "/contacts/#{contact.uid}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(contact.name)
      end
    end

    context "when the record does not exist" do
      it "returns status code 404" do
        get "/contacts/xxx", nil, headers

        expect(last_response.status).to eq(404)
        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end

  describe "GET /contacts/:id?include=provider" do
    context "when provider requested, include provider attributes (just check basics)" do
      it "returns the contact" do
        get "/contacts/#{contact.uid}?include=provider", nil, headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "name")).to eq(contact.name)
        expect(json.dig("included", 0, "id")).to eq(provider.symbol.downcase)
        expect(json.dig("included", 0, "type")).to eq("providers")
        expect(json.dig("included", 0, "attributes", "symbol")).to eq(provider.symbol)
        expect(json.dig("included", 0, "attributes", "displayName")).to eq(provider.display_name)
        expect(json.dig("included", 0, "attributes", "systemEmail")).to eq(provider.system_email)
        expect(json.dig("included", 0, "attributes", "memberType")).to eq(provider.member_type)
      end
    end
  end

  describe "POST /contacts" do
    context "when the request is valid" do
      it "creates a contact" do
        post "/contacts", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Josiah Carberry")
        expect(attributes["email"]).to eq("bob@example.com")
        expect(attributes["roleName"]).to eq(["voting"])
        expect(attributes["fromSalesforce"]).to eq(true)

        relationships = json.dig("data", "relationships")
        expect(relationships).to eq("provider" => { "data" => { "id" => provider.uid, "type" => "providers" } })

        Contact.import
        sleep 2

        get "/contacts", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(3)

        attributes = json.dig("data", 1, "attributes")
        expect(attributes["name"]).to eq("Josiah Carberry")
        expect(attributes["email"]).to start_with("josiah")
        expect(attributes["roleName"]).to eq(["billing"])

        relationships = json.dig("data", 1, "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.symbol.downcase,
        )
      end
    end

    context "when the request is valid consortium_admin" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "givenName" => "Josiah",
              "familyName" => "Carberry",
              "email" => "bob@example.com",
              "roleName" => ["voting"]
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": consortium.uid },
              }
            },
          },
        }
      end
    end

    context "when the request is invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "givenName" => "Josiah",
              "familyName" => "Carberry",
            },
            "relationships": {
              "provider": {
                "data": { "type": "providers", "id": provider.uid },
              },
            },
          },
        }
      end

      it "returns a validation failure message" do
        post "/contacts", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq(
          [
            { "source" => "email", "title" => "Can't be blank" },
          ],
        )
      end
    end
  end

  describe "PUT /contacts/:id" do
    context "when the record exists" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "familyName" => "Smith",
            },
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "familyName")).to eq(
          "Smith",
        )
        expect(json.dig("data", "attributes", "name")).to eq(
          "Josiah Smith",
        )
      end
    end

    context "updates role_name" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "roleName" => ["technical", "voting"],
            },
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "roleName")).to eq(
          ["technical", "voting"],
        )
      end
    end

    context "updates role_name invalid" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "roleName" => ["catering"],
            },
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"]).to eq([{ "source" => "role_name", "title" => "Role name 'catering' is not included in the list of possible role names.", "uid" => contact.uid }])
      end
    end

    # validation has been disabled
    # context "updates role_name already taken" do
    #   let(:params) do
    #     {
    #       "data" => {
    #         "type" => "contacts",
    #         "attributes" => {
    #           "roleName" => ["service"],
    #         },
    #       },
    #     }
    #   end

    #   it "updates the record" do
    #     put "/contacts/#{contact.uid}", params, headers

    #     expect(last_response.status).to eq(422)
    #     expect(json["errors"]).to eq([{ "source" => "role_name", "title" => "Role name 'service' is already taken.", "uid" => contact.uid }])
    #   end
    # end

    context "removes given name and family name" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts", "attributes" => { "givenName" => nil, "familyName" => nil }
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers
        puts last_response.body
        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "givenName")).to be_nil
        expect(json.dig("data", "attributes", "familyName")).to be_nil
        expect(json.dig("data", "attributes", "name")).to be_nil
      end
    end

    context "invalid email" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts", "attributes" => { "email" => "abc" }
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers

        expect(last_response.status).to eq(422)
        expect(json["errors"].first).to eq(
          "source" => "email", "title" => "Email should be valid",
          "uid" => contact.uid
        )
      end
    end
  end

  describe "DELETE /contacts/:id" do
    it "returns status code 204" do
      delete "/contacts/#{contact.uid}", nil, headers

      expect(last_response.status).to eq(204)
    end

    context "when the resource doesnt exist" do
      it "returns status code 404" do
        delete "/contacts/xxx", nil, headers

        expect(last_response.status).to eq(404)
      end

      it "returns a validation failure message" do
        delete "/contacts/xxx", nil, headers

        expect(json["errors"].first).to eq(
          "status" => "404",
          "title" => "The resource you are looking for doesn't exist.",
        )
      end
    end
  end
end
