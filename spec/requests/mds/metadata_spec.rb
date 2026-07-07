# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe "MDS Metadata API", type: :request, vcr: true, prefix_pool_size: 1 do
  let(:provider) do
    create(
      :provider,
      symbol: "DATACITE",
      password: encrypt_password_sha256(ENV["MDS_PASSWORD"]),
    )
  end
  let(:client) do
    create(
      :client,
      provider: provider,
      symbol: ENV["MDS_USERNAME"],
      password: encrypt_password_sha256(ENV["MDS_PASSWORD"]),
    )
  end
  let!(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let(:xml) { file_fixture("datacite.xml").read }
  let(:doi_string) { "10.14454/4K3M-NYVG" }

  let(:mds_host) { { "HTTP_HOST" => "mds.local" } }
  let(:basic_headers) do
    mds_host.merge(
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(
          client.symbol,
          ENV["MDS_PASSWORD"],
        ),
      "CONTENT_TYPE" => "application/xml;charset=UTF-8",
    )
  end

  describe "PUT /metadata/:doi_id" do
    it "registers metadata and returns OK with DOI" do
      put "/metadata/#{doi_string}", xml, basic_headers

      expect(last_response.status).to eq(201)
      expect(last_response.body).to match(%r{\AOK \(10\.14454/4K3M-NYVG\)\z}i)
      expect(last_response.headers["Location"]).to include("/metadata/")

      doi = DataciteDoi.where(doi: doi_string.downcase).first
      expect(doi).to be_present
      expect(doi.source).to eq("mds")
      expect(doi.xml).to be_present
    end

    it "rejects application/x-www-form-urlencoded" do
      put "/metadata/#{doi_string}",
          xml,
          basic_headers.merge(
            "CONTENT_TYPE" => "application/x-www-form-urlencoded",
          )

      expect(last_response.status).to eq(415)
      expect(last_response.body).to include("not supported")
    end
  end

  describe "GET /metadata/:doi_id" do
    it "returns XML for an existing DOI" do
      put "/metadata/#{doi_string}", xml, basic_headers
      get "/metadata/#{doi_string}", nil, basic_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("resource")
      expect(last_response.body).to include("Eating your own Dog Food")
    end

    it "returns 404 for unknown DOI" do
      get "/metadata/10.14454/unknown-doi",
          nil,
          basic_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("DOI is unknown to MDS")
    end
  end

  describe "DELETE /metadata/:doi_id" do
    it "hides a findable DOI (registered state)" do
      put "/metadata/#{doi_string}", xml, basic_headers
      doi = DataciteDoi.where(doi: doi_string.downcase).first
      doi.update_columns(aasm_state: "findable") if doi.draft? || doi.registered?

      delete "/metadata/#{doi_string}", nil, basic_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
      expect(doi.reload).to be_registered
    end
  end
end
