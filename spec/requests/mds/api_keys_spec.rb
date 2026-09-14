# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe "MDS API key authentication", type: :request, vcr: true, prefix_pool_size: 1 do
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
  let!(:api_key_record) { client.api_keys.create!(name: "mds automation key") }
  let(:plain_key) { api_key_record.key }
  let(:xml) { file_fixture("datacite.xml").read }
  let(:doi_string) { "10.14454/4K3M-NYVG" }

  let(:mds_host) { { "HTTP_HOST" => "mds.local" } }
  let(:bearer_headers) do
    mds_host.merge(
      "HTTP_AUTHORIZATION" => "Bearer #{plain_key}",
      "CONTENT_TYPE" => "application/xml;charset=UTF-8",
    )
  end
  let(:basic_key_as_username_headers) do
    mds_host.merge(
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(
          plain_key,
          "ignored",
        ),
      "CONTENT_TYPE" => "application/xml;charset=UTF-8",
    )
  end
  let(:basic_key_as_password_headers) do
    mds_host.merge(
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(
          client.symbol,
          plain_key,
        ),
      "CONTENT_TYPE" => "application/xml;charset=UTF-8",
    )
  end

  describe "Bearer DC.* API key" do
    it "registers metadata with Bearer API key" do
      put "/metadata/#{doi_string}", xml, bearer_headers

      expect(last_response.status).to eq(201)
      expect(last_response.body).to match(%r{\AOK \(10\.14454/4K3M-NYVG\)\z}i)
      expect(last_response.headers["X-Credential-Username"]).to eq(
        client.symbol.downcase,
      )
    end

    it "returns metadata with Bearer API key" do
      put "/metadata/#{doi_string}", xml, bearer_headers
      get "/metadata/#{doi_string}", nil, bearer_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Eating your own Dog Food")
    end

    it "returns landing URL with Bearer API key" do
      doi =
        create(
          :doi,
          client: client,
          doi: "10.14454/mds-api-key-url",
          aasm_state: "draft",
          url: "https://example.org/api-key-landing",
        )

      get "/doi/#{doi.doi}", nil, bearer_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("https://example.org/api-key-landing")
    end

    it "authorizes GET /doi list (get_urls) with Bearer API key" do
      get "/doi", nil, bearer_headers.except("CONTENT_TYPE")

      expect(last_response.status).to be_in([200, 204])
      expect(last_response.body).not_to eq("Access is denied")
    end

    it "creates media with Bearer API key" do
      doi =
        create(
          :doi,
          client: client,
          doi: "10.14454/mds-api-key-media",
          aasm_state: "findable",
        )

      post "/media/#{doi.doi}",
           "application/pdf=https://example.org/file.pdf",
           bearer_headers.merge("CONTENT_TYPE" => "text/plain")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
      expect(doi.media.count).to eq(1)
    end

    it "returns 401 for an invalid Bearer API key" do
      headers =
        mds_host.merge("HTTP_AUTHORIZATION" => "Bearer DC.invalidkey000000000000000000000")
      get "/doi/10.14454/anything", nil, headers

      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq("Bad credentials")
    end
  end

  describe "Basic with API key as username" do
    it "registers metadata when DC.* is the Basic username" do
      put "/metadata/#{doi_string}", xml, basic_key_as_username_headers

      expect(last_response.status).to eq(201)
      expect(last_response.body).to match(%r{\AOK \(10\.14454/4K3M-NYVG\)\z}i)
    end
  end

  describe "Basic with API key as password" do
    it "returns DOI URL when DC.* is the Basic password for the client" do
      doi =
        create(
          :doi,
          client: client,
          doi: "10.14454/mds-api-key-basic-pw",
          aasm_state: "draft",
          url: "https://example.org/basic-key",
        )

      get "/doi/#{doi.doi}",
          nil,
          basic_key_as_password_headers.except("CONTENT_TYPE")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("https://example.org/basic-key")
    end
  end
end
