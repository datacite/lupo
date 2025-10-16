# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request do
  let(:admin) { create(:provider, symbol: "ADMIN") }
  let(:admin_bearer) { Client.generate_token(role_id: "staff_admin", uid: admin.symbol, password: admin.password) }
  let(:admin_headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + admin_bearer } }

  let(:provider) { create(:provider, symbol: "DATACITE", password: encrypt_password_sha256(ENV["MDS_PASSWORD"])) }
  let(:client) { create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: encrypt_password_sha256(ENV["MDS_PASSWORD"]), re3data_id: "10.17616/r3xs37") }
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }

  let(:doi) { create(:doi, client: client, doi: "10.14454/4K3M-NYVG") }
  let(:bearer) { Client.generate_token(role_id: "client_admin", uid: client.symbol, provider_id: provider.symbol.downcase, client_id: client.symbol.downcase, password: client.password) }
  let(:headers) { { "HTTP_ACCEPT" => "application/vnd.api+json", "HTTP_AUTHORIZATION" => "Bearer " + bearer } }

  describe "PATCH /dois/:id" do
    context "update geoLocationPoint" do
      let(:geo_locations) { [
        {
          "geoLocationPoint" => {
            "pointLatitude" => "49.0850736",
            "pointLongitude" => "-123.3300992"
          }
        }] }
      let(:geo_locations_numeric) { [
        {
          "geoLocationPoint" => {
            "pointLatitude" => 49.0850736,
            "pointLongitude" => -123.3300992
          }
        }] }
      let(:update_attributes) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "geoLocations" => geo_locations
            }
          }
        }
      end
      let(:update_attributes_numeric) do
        {
          "data" => {
            "type" => "dois",
            "attributes" => {
              "geoLocations" => geo_locations_numeric
            }
          }
        }
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "geoLocations")).to eq(geo_locations_numeric)

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("geoLocations", "geoLocation").to_s + "\n").to eq(
          <<~HEREDOC
            <geoLocations>
              <geoLocation>
                <geoLocationPoint>
                  <pointLatitude>49.0850736</pointLatitude>
                  <pointLongitude>-123.3300992</pointLongitude>
                </geoLocationPoint>
              </geoLocation>
            </geoLocations>
          HEREDOC
        )
      end

      it "updates the Doi" do
        patch "/dois/#{doi.doi}", update_attributes_numeric, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data", "attributes", "geoLocations")).to eq(geo_locations_numeric)

        doc = Nokogiri::XML(Base64.decode64(json.dig("data", "attributes", "xml")), nil, "UTF-8", &:noblanks)
        expect(doc.at_css("geoLocations", "geoLocation").to_s + "\n").to eq(
          <<~HEREDOC
            <geoLocations>
              <geoLocation>
                <geoLocationPoint>
                  <pointLatitude>49.0850736</pointLatitude>
                  <pointLongitude>-123.3300992</pointLongitude>
                </geoLocationPoint>
              </geoLocation>
            </geoLocations>
          HEREDOC
        )
      end
    end
  end
end
