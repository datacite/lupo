# frozen_string_literal: true

require "rails_helper"

describe DataciteDoisController, type: :request, vcr: true do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: ENV["MDS_PASSWORD"], re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "POST /dois" do
    context "when the request is valid" do
      let(:xml) { Base64.strict_encode64(file_fixture("datacite.xml").read) }
      let(:valid_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "doi" => "10.14454/10703",
              "url" => "http://www.bl.uk/pdf/patspec.pdf",
              "xml" => xml,
              "source" => "test",
              "event" => "publish",
            },
          },
        }
      end

      let(:headers) do
        {
          "CONTENT_TYPE" => "application/gzip",
          "HTTP_ACCEPT" => "application/vnd.api+json",
          "HTTP_AUTHORIZATION" => "Bearer " + bearer,
          "HTTP_CONTENT_ENCODING" => "gzip",
        }
      end

      let(:valid_json) { valid_attributes.to_json }
      let(:gzipped) { ActiveSupport::Gzip.compress(valid_json) }

      before do
        post "/dois", gzipped, headers
      end

      it "create a doi from compressed input successfully" do
        expect(last_response.status).to eq(201)
      end
    end
  end
end
