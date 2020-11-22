# frozen_string_literal: true

require "rails_helper"

describe "Provider session", type: :request do
  let!(:provider) { create(:provider, password_input: "12345") }

  context "request is valid" do
    let(:params) do
      "grant_type=password&username=#{provider.symbol}&password=12345"
    end

    it "creates a provider token" do
      post "/token", params

      expect(last_response.status).to eq(200)
      payload = provider.decode_token(json.fetch("access_token", {}))
      expect(payload["role_id"]).to eq("provider_admin")
      expect(payload["provider_id"]).to eq(provider.symbol.downcase)
      expect(payload["name"]).to eq(provider.name)
    end
  end

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

describe "Admin session", type: :request do
  let!(:provider) do
    create(
      :provider,
      role_name: "ROLE_ADMIN",
      name: "Admin",
      symbol: "ADMIN",
      password_input: "12345",
    )
  end

  context "request is valid" do
    let(:params) do
      "grant_type=password&username=#{provider.symbol}&password=12345"
    end

    it "creates a provider token" do
      post "/token", params

      expect(last_response.status).to eq(200)
      payload = provider.decode_token(json.fetch("access_token", {}))
      expect(payload["role_id"]).to eq("staff_admin")
      expect(payload["name"]).to eq(provider.name)
    end
  end
end

describe "Client session", type: :request do
  let!(:client) { create(:client, password_input: "12345") }

  context "request is valid" do
    let(:params) do
      "grant_type=password&username=#{client.symbol}&password=12345"
    end

    it "creates a client token" do
      post "/token", params

      expect(last_response.status).to eq(200)
      payload = client.decode_token(json.fetch("access_token", {}))
      expect(payload["role_id"]).to eq("client_admin")
      expect(payload["client_id"]).to eq(client.symbol.downcase)
      expect(payload["name"]).to eq(client.name)
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

# describe "Openid connect session", type: :request  do
#   context 'role user' do
#     let(:user) { create(:user, uid: "0000-0003-1419-2405") }
#     let(:params) { "token=" + User.generate_alb_token(preferred_username: user.uid + "@orcid.org", name: user.name) }

#     it 'creates a user token' do
#       post '/oidc-token', params, { 'HTTP_ACCEPT'=>'application/x-www-form-urlencoded' }

#       expect(last_response.status).to eq(200)
#       payload = user.decode_token(json.fetch('access_token', {}))
#       expect(payload["uid"]).to eq("0000-0003-1419-2405")
#       expect(payload["role_id"]).to eq("user")
#       expect(payload["name"]).to eq(user.name)
#     end
#   end

#   context 'role staff_admin' do
#     let!(:user) { create(:user, uid: "0000-0003-1419-2405", role_id: "staff_admin") }
#     let(:params) { "token=" + User.generate_alb_token(preferred_username: user.uid + "@orcid.org", name: user.name) }

#     it 'creates a user token' do
#       post '/oidc-token', params, { 'HTTP_ACCEPT'=>'application/x-www-form-urlencoded' }
#       expect(last_response.status).to eq(200)
#       payload = user.decode_token(json.fetch('access_token', {}))
#       expect(payload["uid"]).to eq("0000-0003-1419-2405")
#       expect(payload["role_id"]).to eq("staff_admin")
#       expect(payload["name"]).to eq(user.name)
#     end
#   end
# end
