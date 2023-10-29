# frozen_string_literal: true

require "rails_helper"

describe ActivitiesController, type: :request do
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) do
    create(
      :client,
      provider: provider,
      symbol: ENV["MDS_USERNAME"],
      password: ENV["MDS_PASSWORD"],
    )
  end
  let(:doi) { create(:doi, client: client) }
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

  describe "activities for doi", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "without username" do
      it "returns the activities" do
        get "/dois/#{doi.doi.downcase}/activities",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")
        expect(
          json.dig("data", 0, "attributes", "changes", "aasm_state"),
        ).to eq("draft")

        expect(
          json.dig("data", 0, "attributes", "prov:wasAttributedTo"),
        ).to be_nil
        expect(
          json.dig("data", 0, "attributes", "prov:wasGeneratedBy"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:generatedAtTime"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:wasDerivedFrom"),
        ).to be_present
      end
    end
  end

  describe "activities for repository", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "repository" do
      it "returns the activities" do
        get "/repositories/#{client.symbol.downcase}/activities",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")

        expect(
          json.dig("data", 0, "attributes", "prov:wasAttributedTo"),
        ).to be_nil
        expect(
          json.dig("data", 0, "attributes", "prov:wasGeneratedBy"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:generatedAtTime"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:wasDerivedFrom"),
        ).to be_present
      end
    end
  end

  describe "activities for provider", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "provider" do
      it "returns the activities" do
        get "/providers/#{provider.symbol.downcase}/activities",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")

        expect(
          json.dig("data", 0, "attributes", "prov:wasAttributedTo"),
        ).to be_nil
        expect(
          json.dig("data", 0, "attributes", "prov:wasGeneratedBy"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:generatedAtTime"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:wasDerivedFrom"),
        ).to be_present
      end
    end
  end

  describe "query activities", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "query by doi" do
      it "returns the activities" do
        get "/activities?datacite-doi-id=#{doi.doi.downcase}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")
        expect(
          json.dig("data", 0, "attributes", "changes", "aasm_state"),
        ).to eq("draft")

        expect(
          json.dig("data", 0, "attributes", "prov:wasAttributedTo"),
        ).to be_nil
        expect(
          json.dig("data", 0, "attributes", "prov:wasGeneratedBy"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:generatedAtTime"),
        ).to be_present
        expect(
          json.dig("data", 0, "attributes", "prov:wasDerivedFrom"),
        ).to be_present
      end
    end
  end

  describe "query activities - when the publisher param is not 'true'", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "query by doi" do
      it "returns the activities" do
        get "/activities?datacite-doi-id=#{doi.doi.downcase}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")
        expect(json.dig("data", 0, "attributes", "changes", "publisher")).to eq("Dryad Digital Repository")
      end
    end
  end

  describe "query activities - when the publisher param is set to true", elasticsearch: true do
    let!(:doi) { create(:doi, client: client) }
    let!(:other_doi) { create(:doi, client: client) }

    before do
      DataciteDoi.import
      Activity.import
      sleep 2
    end

    context "query by doi" do
      it "returns the activities" do
        get "/activities?publisher=true&datacite-doi-id=#{doi.doi.downcase}",
            nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").length).to eq(1)
        expect(json.dig("meta", "total")).to eq(1)
        expect(json.dig("data", 0, "attributes", "action")).to eq("create")
        expect(json.dig("data", 0, "attributes", "changes", "publisher")).to eq(
          {
            "lang" => "en",
            "name" => "Dryad Digital Repository",
            "schemeUri" => "https://ror.org/",
            "publisherIdentifier" => "https://ror.org/00x6h5n95",
            "publisherIdentifierScheme" => "ROR"
          }
        )
      end
    end
  end
end
