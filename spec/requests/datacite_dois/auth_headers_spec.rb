# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request, vcr: true do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let(:provider_member_only) { create(:provider, role_name: "ROLE_MEMBER", symbol: "YYYY", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: encrypt_password_sha256(ENV["MDS_PASSWORD"]), re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "GET /dois with authorization headers", elasticsearch: true do
    let!(:dois) { create_list(:doi, 10, client: client, aasm_state: "findable") }
    let!(:doi_draft) { create(:doi, client: client, aasm_state: "draft") }
    let!(:doi_registered) { create(:doi, client: client, aasm_state: "registered") }
    let(:anonymous_basic_auth_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, "") } }
    let(:client_basic_auth_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(client.symbol, ENV["MDS_PASSWORD"]) } }
    let(:provider_basic_auth_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(provider.symbol, ENV["MDS_PASSWORD"]) } }
    let(:provider_member_only_basic_auth_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(provider_member_only.symbol, ENV["MDS_PASSWORD"]) } }

    before do
      DataciteDoi.import
      sleep 2
    end

    it "return only findable dois with no authorization" do
      get "/dois"

      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1)).to eq(nil)
      expect(json.dig("meta", "states", 2)).to eq(nil)
    end

    it "return only findable dois with anonymous user" do
      get "/dois", nil, anonymous_basic_auth_headers

      expect(json.dig("meta", "total")).to eq(10)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1)).to eq(nil)
      expect(json.dig("meta", "states", 2)).to eq(nil)
    end

    it "return dois in all states with authenticated client user" do
      get "/dois", nil, client_basic_auth_headers

      expect(json.dig("meta", "total")).to eq(12)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1, "count")).to eq(1)
      expect(json.dig("meta", "states", 2, "count")).to eq(1)
    end

    it "return dois in all states with authenticated provider user" do
      get "/dois", nil, provider_basic_auth_headers

      expect(json.dig("meta", "total")).to eq(12)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1, "count")).to eq(1)
      expect(json.dig("meta", "states", 2, "count")).to eq(1)
    end

    it "return dois in all states with authenticated ROLE_MEMBER provider user" do
      get "/dois", nil, provider_member_only_basic_auth_headers

      expect(json.dig("meta", "total")).to eq(12)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1, "count")).to eq(1)
      expect(json.dig("meta", "states", 2, "count")).to eq(1)
    end

    it "return dois in all states with authenticated admin user" do
      get "/dois", nil, admin_headers

      expect(json.dig("meta", "total")).to eq(12)
      expect(json.dig("meta", "states", 0, "count")).to eq(10)
      expect(json.dig("meta", "states", 1, "count")).to eq(1)
      expect(json.dig("meta", "states", 2, "count")).to eq(1)
    end
  end
end
