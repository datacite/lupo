# frozen_string_literal: true

require "rails_helper"

describe ContactsController, type: :request, elasticsearch: true do
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider) }
  let!(:contact) { create(:contact, provider: provider) }
  let(:params) do
    {
      "data" => {
        "type" => "contacts",
        "attributes" => {
          "givenName" => "Josiah",
          "familyName" => "Carberry",
          "email" => "bob@example.com",
          "roles" => ["voting_contact"]
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

  describe "GET /contacts", elasticsearch: true do
    let!(:contacts) { create_list(:contact, 3) }

    before do
      Contact.import
      sleep 1
    end

    it "returns contacts" do
      get "/contacts", nil, headers

      expect(last_response.status).to eq(200)
      expect(json["data"].size).to eq(4)
      expect(json.dig("meta", "total")).to eq(4)
    end
  end

  describe "GET /contacts query" do
    before { get "/contacts?query=carberry", nil, headers }

    it "returns contacts" do
      expect(last_response.status).to eq(200)
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(0)
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

  describe "POST /contacts" do
    context "when the request is valid" do
      it "creates a contact" do
        post "/contacts", params, headers

        expect(last_response.status).to eq(201)
        attributes = json.dig("data", "attributes")
        expect(attributes["name"]).to eq("Josiah Carberry")
        expect(attributes["email"]).to eq("bob@example.com")
        expect(attributes["roles"]).to eq(["voting_contact"])

        relationships = json.dig("data", "relationships")
        expect(relationships).to eq("provider" => { "data" => { "id" => provider.uid, "type" => "providers" } })

        Contact.import
        sleep 2

        get "/contacts", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(2)

        attributes = json.dig("data", 0, "attributes")
        expect(attributes["name"]).to eq("Josiah Carberry")
        expect(attributes["email"]).to eq("josiah@example.org")
        expect(attributes["roles"]).to eq(["voting_contact"])

        relationships = json.dig("data", 0, "relationships")
        expect(relationships.dig("provider", "data", "id")).to eq(
          provider.uid,
        )
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

    context "updates roles" do
      let(:params) do
        {
          "data" => {
            "type" => "contacts",
            "attributes" => {
              "roles" => ["technical_contact", "service_contact"],
            },
          },
        }
      end

      it "updates the record" do
        put "/contacts/#{contact.uid}", params, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "roles")).to eq(
          ["technical_contact", "service_contact"],
        )
      end
    end

    # context "updates roles invalid" do
    #   let(:params) do
    #     {
    #       "data" => {
    #         "type" => "contacts",
    #         "attributes" => {
    #           "roles" => ["technical_contact", "service_contact"],
    #         },
    #       },
    #     }
    #   end

    #   it "updates the record" do
    #     put "/contacts/#{contact.uid}", params, headers

    #     expect(last_response.status).to eq(200)
    #     expect(json.dig("data", "attributes", "roles")).to eq(
    #       ["technical_contact", "service_contact"],
    #     )
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
