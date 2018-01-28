require 'rails_helper'

describe "Provider session", type: :request  do
  let!(:provider) { create(:provider, password_input: "12345") }

  context 'request is valid' do
    let(:params) { "grant_type=password&username=#{provider.symbol}&password=12345" }

    before { post '/token', params: params, headers: nil }

    it 'creates a provider token' do
      payload = provider.decode_token(json.fetch('access_token', {}))
      expect(payload["role_id"]).to eq("provider_admin")
      expect(payload["name"]).to eq(provider.name)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  context 'wrong grant_type' do
    let(:params) { "grant_type=client_credentials&client_id=#{provider.symbol}&client_secret=12345" }

    before { post '/token', params: params, headers: nil }

    it 'returns an error' do
      expect(json.fetch('errors', {})).to eq([{"status"=>"400", "title"=>"Wrong grant type."}])
    end

    it 'returns status code 400' do
      expect(response).to have_http_status(400)
    end
  end

  context 'missing password' do
    let(:params) { "grant_type=password&username=#{provider.symbol}" }

    before { post '/token', params: params, headers: nil }

    it 'returns an error' do
      expect(json.fetch('errors', {})).to eq([{"status"=>"400", "title"=>"Missing account or password."}])
    end

    it 'returns status code 400' do
      expect(response).to have_http_status(400)
    end
  end

  context 'wrong password' do
    let(:params) { "grant_type=password&username=#{provider.symbol}&password=12346" }

    before { post '/token', params: params, headers: nil }

    it 'returns an error' do
      expect(json.fetch('errors', {})).to eq([{"status"=>"400", "title"=>"Wrong account or password."}])
    end

    it 'returns status code 400' do
      expect(response).to have_http_status(400)
    end
  end
end

describe "Admin session", type: :request  do
  let!(:provider) { create(:provider, role_name: "ROLE_ADMIN", name: "Admin", symbol: "ADMIN", password_input: "12345") }

  context 'request is valid' do
    let(:params) { "grant_type=password&username=#{provider.symbol}&password=12345" }

    before { post '/token', params: params, headers: nil }

    it 'creates a provider token' do
      payload = provider.decode_token(json.fetch('access_token', {}))
      expect(payload["role_id"]).to eq("staff_admin")
      expect(payload["name"]).to eq(provider.name)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end

describe "Client session", type: :request  do
  let!(:client) { create(:client, password_input: "12345") }

  context 'request is valid' do
    let(:params) { "grant_type=password&username=#{client.symbol}&password=12345" }

    before { post '/token', params: params, headers: nil }

    it 'creates a client token' do
      payload = client.decode_token(json.fetch('access_token', {}))
      expect(payload["role_id"]).to eq("client_admin")
      expect(payload["name"]).to eq(client.name)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
