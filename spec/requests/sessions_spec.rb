# frozen_string_literal: true

require "rails_helper"

describe "Provider session", type: :request do
  let!(:provider) { create(:provider, password_input: "12345") }

  context "wrong grant_type" do
    let(:params) do
      "grant_type=client_credentials&client_id=#{
        provider.symbol
      }&client_secret=12345"
    end

    it "returns an error" do
      post "/token", params

      expect(last_response.status).to eq(400)
      expect(json.fetch("errors", {})).to eq(
        [{ "status" => "400", "title" => "Wrong grant type." }],
      )
    end
  end

  context "missing password" do
    let(:params) { "grant_type=password&username=#{provider.symbol}" }

    it "returns an error" do
      post "/token", params

      expect(last_response.status).to eq(400)
      expect(json.fetch("errors", {})).to eq(
        [{ "status" => "400", "title" => "Missing account ID or password." }],
      )
    end
  end

  context "wrong password" do
    let(:params) do
      "grant_type=password&username=#{provider.symbol}&password=12346"
    end

    it "returns an error" do
      post "/token", params

      expect(last_response.status).to eq(400)
      expect(json.fetch("errors", {})).to eq(
        [{ "status" => "400", "title" => "Wrong account ID or password." }],
      )
    end
  end
end

describe "reset", type: :request, vcr: true do
  let(:provider) do
    create(:provider, symbol: "DATACITE", password_input: "12345")
  end
  let!(:client) do
    create(
      :client,
      symbol: "DATACITE.DATACITE", password_input: "12345", provider: provider,
    )
  end

  context "account exists" do
    let(:params) { "username=#{client.symbol}" }

    it "sends a message" do
      post "/reset", params

      expect(last_response.status).to eq(200)
      expect(json["message"]).to eq("Queued. Thank you.")
    end
  end

  context "account is missing" do
    let(:params) { "username=a" }

    it "sends a message" do
      post "/reset", params

      expect(last_response.status).to eq(200)
      expect(json["message"]).to eq("Account not found.")
    end
  end

  context "account ID not provided" do
    let(:params) { "username=" }

    it "sends a message" do
      post "/reset", params

      expect(last_response.status).to eq(200)
      expect(json["message"]).to eq("Missing account ID.")
    end
  end
end
