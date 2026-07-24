# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe "MDS Media API", type: :request, vcr: true, prefix_pool_size: 1 do
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
  let!(:doi) do
    create(
      :doi,
      client: client,
      doi: "10.14454/mds-media-1",
      aasm_state: "findable",
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

  describe "POST /media/:doi_id" do
    it "creates media from mediaType=url body" do
      post "/media/#{doi.doi}",
           "application/pdf=https://example.org/file.pdf",
           basic_headers.merge("CONTENT_TYPE" => "text/plain")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("OK")
      expect(doi.media.count).to eq(1)
      expect(doi.media.first.media_type).to eq("application/pdf")
      expect(doi.media.first.url).to eq("https://example.org/file.pdf")
    end
  end

  describe "GET /media/:doi_id" do
    it "lists media as mediaType=url lines" do
      create(
        :media,
        doi: doi,
        media_type: "application/pdf",
        url: "https://example.org/a.pdf",
      )
      create(
        :media,
        doi: doi,
        media_type: "text/plain",
        url: "https://example.org/a.txt",
      )

      get "/media/#{doi.doi}", nil, basic_headers

      expect(last_response.status).to eq(200)
      lines = last_response.body.split("\n")
      expect(lines).to include("application/pdf=https://example.org/a.pdf")
      expect(lines).to include("text/plain=https://example.org/a.txt")
    end

    it "returns 404 when no media exist" do
      get "/media/#{doi.doi}", nil, basic_headers

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("No media for the DOI")
    end
  end

  describe "nested /doi/:doi_id/media" do
    it "lists media via nested path" do
      create(
        :media,
        doi: doi,
        media_type: "application/json",
        url: "https://example.org/data.json",
      )

      get "/doi/#{doi.doi}/media", nil, basic_headers

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include(
        "application/json=https://example.org/data.json",
      )
    end
  end
end
