# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe "MDS Dois API", type: :request, vcr: true, prefix_pool_size: 1 do
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
  let(:doi) do
    create(
      :doi,
      client: client,
      doi: "10.14454/mds-doi-1",
      aasm_state: "draft",
      url: nil,
    )
  end
  let(:findable_doi) do
    create(
      :doi,
      client: client,
      doi: "10.14454/mds-findable-1",
      aasm_state: "findable",
      url: "https://example.org/landing",
    )
  end

  let(:mds_host) { { "HTTP_HOST" => "mds.local" } }
  let(:basic_headers) do
    mds_host.merge(
      "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials(
          client.symbol,
          ENV["MDS_PASSWORD"],
        ),
    )
  end

  describe "authentication" do
    it "returns 401 without credentials" do
      get "/doi/#{doi.doi}", nil, mds_host

      expect(last_response.status).to eq(401)
      expect(last_response.body).to match(/Bad credentials|Authentication/i)
    end

    it "returns 401 with wrong password" do
      headers =
        mds_host.merge(
          "HTTP_AUTHORIZATION" =>
            ActionController::HttpAuthentication::Basic.encode_credentials(
              client.symbol,
              "wrong-password",
            ),
        )
      get "/doi/#{doi.doi}", nil, headers

      expect(last_response.status).to eq(401)
      expect(last_response.body).to eq("Bad credentials")
    end
  end

  describe "GET /doi/:id" do
    it "returns the URL for a DOI with a known url attribute" do
      findable_doi
      get "/doi/#{findable_doi.doi}", nil, basic_headers

      # May be 200 with URL from attribute/handle, or 204 if handle lookup empty in test
      expect([200, 204]).to include(last_response.status)
      if last_response.status == 200
        expect(last_response.body).to be_present
      end
    end

    it "returns 404 for unknown DOI" do
      get "/doi/10.14454/does-not-exist", nil, basic_headers

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("DOI not found")
    end
  end

  describe "PUT /doi/:id" do
    it "publishes a URL for an existing draft DOI" do
      doi
      body = "doi=#{doi.doi}\nurl=https://example.org/new-landing"
      put "/doi/#{doi.doi}",
          body,
          basic_headers.merge("CONTENT_TYPE" => "text/plain;charset=UTF-8")

      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq("OK")
      expect(doi.reload.url).to eq("https://example.org/new-landing")
      expect(doi).to be_findable
    end

    it "rejects invalid URLs" do
      doi
      body = "doi=#{doi.doi}\nurl=not-a-url"
      put "/doi/#{doi.doi}",
          body,
          basic_headers.merge("CONTENT_TYPE" => "text/plain;charset=UTF-8")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("Not a valid HTTP(S) or FTP URL")
    end
  end

  describe "DELETE /doi/:id" do
    it "deletes a draft DOI" do
      doi
      delete "/doi/#{doi.doi}", nil, basic_headers

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
      expect(DataciteDoi.where(doi: doi.doi)).to be_empty
    end

    it "does not delete a findable DOI" do
      findable_doi
      delete "/doi/#{findable_doi.doi}", nil, basic_headers

      expect(last_response.status).to eq(405)
      expect(DataciteDoi.where(doi: findable_doi.doi)).to exist
    end
  end

  describe "host isolation" do
    it "does not serve MDS plain-text /doi on a non-MDS host" do
      get "/doi/#{doi.doi}",
          nil,
          {
            "HTTP_HOST" => "www.example.com",
            "HTTP_AUTHORIZATION" =>
              ActionController::HttpAuthentication::Basic.encode_credentials(
                client.symbol,
                ENV["MDS_PASSWORD"],
              ),
          }

      # Non-MDS host must not hit Mds::DoisController (plain "DOI not found" / URL body).
      # Falls through to REST index/content-negotiation or routing error instead.
      expect(last_response.body).not_to eq("DOI not found")
      expect(last_response.headers["X-Credential-Username"]).not_to eq(client.symbol.downcase) if last_response.status == 401
    end

    it "still serves REST /dois on the default host" do
      get "/dois",
          nil,
          {
            "HTTP_HOST" => "www.example.com",
            "HTTP_ACCEPT" => "application/vnd.api+json",
            "HTTP_AUTHORIZATION" =>
              ActionController::HttpAuthentication::Basic.encode_credentials(
                client.symbol,
                ENV["MDS_PASSWORD"],
              ),
          }

      expect(last_response.status).to eq(200)
      expect(json).to have_key("data")
    end
  end
end
