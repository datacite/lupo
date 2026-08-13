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

    it "rejects path DOI that does not match metadata identifier" do
      put "/metadata/10.14454/other-doi", xml, basic_headers

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq(
        "doi parameter does not match doi of resource",
      )
      expect(DataciteDoi.where(doi: "10.14454/other-doi").count).to eq(0)
      expect(DataciteDoi.where(doi: doi_string.downcase).count).to eq(0)
    end
  end

  describe "POST /metadata" do
    it "rejects minting when path and body provide no valid prefix" do
      expect {
        post "/metadata", "", basic_headers
      }.not_to change(DataciteDoi, :count)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("No valid prefix found")
    end

    it "rejects minting when path is not a valid prefix" do
      expect {
        post "/metadata/not-a-prefix", "", basic_headers
      }.not_to change(DataciteDoi, :count)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("No valid prefix found")
    end

    it "rejects minting when metadata has no identifier and path is blank" do
      body = xml.sub(
        %r{<identifier[^>]*>.*?</identifier>}m,
        "<identifier identifierType=\"DOI\"></identifier>",
      )

      expect {
        post "/metadata", body, basic_headers
      }.not_to change(DataciteDoi, :count)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("No valid prefix found")
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

    context "cross-client visibility" do
      let(:other_client) do
        create(
          :client,
          provider: provider,
          symbol: "DATACITE.OTHER",
          password: encrypt_password_sha256(ENV["MDS_PASSWORD"]),
        )
      end
      let!(:other_client_prefix) do
        create(:client_prefix, client: other_client, prefix: prefix)
      end

      it "does not leak another repository's draft metadata" do
        draft =
          create(
            :doi,
            client: other_client,
            doi: "10.14454/other-draft-meta",
            aasm_state: "draft",
          )
        draft.update_columns(xml: xml)

        get "/metadata/#{draft.doi}",
            nil,
            basic_headers.except("CONTENT_TYPE")

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq("DOI is unknown to MDS")
      end

      it "allows reading another repository's findable metadata" do
        findable =
          create(
            :doi,
            client: other_client,
            doi: "10.14454/other-findable-meta",
            aasm_state: "findable",
            url: "https://example.org/public",
          )
        findable.update_columns(xml: xml)

        get "/metadata/#{findable.doi}",
            nil,
            basic_headers.except("CONTENT_TYPE")

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("resource")
      end
    end
  end

  describe "PUT /metadata path vs non-DataCite body identifier" do
    it "rejects path DOI that does not match schema.org @id" do
      body = file_fixture("schema_org.json").read
      # fixture @id is 10.5438/4K3M-NYVG — detected as schema_org by body shape
      put "/metadata/10.14454/other-doi",
          body,
          basic_headers.merge("CONTENT_TYPE" => "application/json")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq(Mds::PATH_BODY_MISMATCH)
      expect(DataciteDoi.where(doi: "10.14454/other-doi").count).to eq(0)
    end
  end

  describe "DELETE /metadata/:doi_id" do
    it "hides a findable DOI (registered state)" do
      put "/metadata/#{doi_string}", xml, basic_headers
      doi = DataciteDoi.where(doi: doi_string.downcase).first
      # findable DOIs always have a landing URL; update_url/register_url requires it
      if doi.draft? || doi.registered?
        doi.update_columns(
          aasm_state: "findable",
          url: "https://example.org/mds-metadata-hide",
        )
      end

      delete "/metadata/#{doi_string}", nil, basic_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
      expect(doi.reload).to be_registered
    end
  end
end
