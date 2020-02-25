require "rails_helper"

describe "exports", type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer} }

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD']) }
  let!(:prefix) { create(:prefix, prefix: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer }}
  let!(:dois) { create_list(:doi, 3, client: client, aasm_state: "findable") }

  describe "GET /export/organizations", elasticsearch: true do

    before do
      Doi.import
      Provider.import
      sleep 2
    end

    it 'returns organizations', vcr: false do
      get "/export/organizations", nil, headers

      expect(last_response.status).to eq(200)
    end

  end

  describe "GET /export/repositories", elasticsearch: true do

    before do
      Doi.import
      Client.import
      sleep 2
    end

    it 'returns repositories', vcr: false do
      get "/export/repositories", nil, headers

      expect(last_response.status).to eq(200)
    end

  end

  describe "GET /export/contacts", elasticsearch: true do

    before do
      Doi.import
      Client.import
      Provider.import
      sleep 2
    end

    it 'returns contacts', vcr: false do
      get "/export/contacts", nil, headers

      expect(last_response.status).to eq(200)
    end

  end

end
