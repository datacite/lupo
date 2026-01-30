# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enrichments", type: :request do
  before do
    allow_any_instance_of(Enrichment).to receive(:validate_json_schema)
  end

  def create_enrichment!(doi:, updated_at:)
    Enrichment.create!(
      doi: doi,
      contributors: [{ name: "X", contributorType: "ResearchGroup" }],
      resources: [{ relatedIdentifier: "10.1234/x", relationType: "IsDerivedFrom", relatedIdentifierType: "DOI" }],
      field: "creators",
      action: "updateChild",
      original_value: { name: "Old" },
      enriched_value: { name: "New" },
      updated_at: updated_at
    )
  end

  def json
    JSON.parse(response.body)
  end

  describe "GET /enrichments" do
    it "returns 400 when both doi and client_id are missing" do
      get "/enrichments"

      expect(response).to have_http_status(:bad_request)
      expect(json).to eq("message" => "Missing doi or client-id query string parameter")
    end

    it "filters by doi when doi param is provided" do
      doi_a = create(:doi)
      doi_b = create(:doi)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      e1 = create_enrichment!(doi: doi_a.doi, updated_at: t)
      _e2 = create_enrichment!(doi: doi_b.doi, updated_at: t)

      get "/enrichments", params: { doi: doi_a.doi }

      expect(response).to have_http_status(:ok)
      expect(json["data"].map { |h| h["id"] }).to eq([e1.id])
    end

    it "filters by client_id when client_id param is provided" do
      provider = create(:provider)
      client_a = create(:client, provider: provider, symbol: "#{provider.symbol}.DATACITE.TEST")
      client_b = create(:client, provider: provider, symbol: "#{provider.symbol}.OTHER.TEST")

      doi_a = create(:doi, client: client_a)
      doi_b = create(:doi, client: client_b)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      e1 = create_enrichment!(doi: doi_a.doi, updated_at: t)
      _e2 = create_enrichment!(doi: doi_b.doi, updated_at: t)

      get "/enrichments", params: { client_id: client_a.symbol }

      expect(response).to have_http_status(:ok)
      expect(json["data"].map { |h| h["id"] }).to eq([e1.id])
    end

    it "orders results by updated_at desc then id desc" do
      doi = create(:doi)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      a = create_enrichment!(doi: doi.doi, updated_at: t)
      b = create_enrichment!(doi: doi.doi, updated_at: t)
      c = create_enrichment!(doi: doi.doi, updated_at: t + 1.second)

      get "/enrichments", params: { doi: doi.doi }

      ids = json["data"].map { |h| h["id"] }
      expected_same_time = [a.id, b.id].sort.reverse
      expect(ids).to eq([c.id] + expected_same_time)
    end

    it "includes links.self and links.next is nil when fewer than PAGE_SIZE results" do
      doi = create(:doi)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      3.times { |i| create_enrichment!(doi: doi.doi, updated_at: t + i.seconds) }

      get "/enrichments", params: { doi: doi.doi }

      expect(response).to have_http_status(:ok)
      expect(json.dig("links", "self")).to be_present
      expect(json.dig("links", "next")).to be_nil
    end

    it "sets links.next when exactly PAGE_SIZE results are returned" do
      stub_const("EnrichmentsController::PAGE_SIZE", 2)

      doi = create(:doi)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      create_enrichment!(doi: doi.doi, updated_at: t)
      create_enrichment!(doi: doi.doi, updated_at: t + 1.second)

      get "/enrichments", params: { doi: doi.doi }

      expect(response).to have_http_status(:ok)
      expect(json.dig("links", "next")).to be_present
      expect(json.dig("links", "next")).to include("cursor=")
      expect(json.dig("links", "next")).to include("doi=#{doi.doi}")
    end

    it "paginates with cursor so the next page excludes the cursor record and newer ones" do
      stub_const("EnrichmentsController::PAGE_SIZE", 2)

      doi = create(:doi)
      t = Time.utc(2026, 1, 29, 10, 0, 0)

      newest = create_enrichment!(doi: doi.doi, updated_at: t + 3.seconds)
      mid    = create_enrichment!(doi: doi.doi, updated_at: t + 2.seconds)
      older  = create_enrichment!(doi: doi.doi, updated_at: t + 1.second)

      # Page 1
      get "/enrichments", params: { doi: doi.doi }

      expect(response).to have_http_status(:ok)
      ids1 = json["data"].map { |h| h["id"] }
      expect(ids1).to eq([newest.id, mid.id])

      # Build a cursor that represents "mid" (the last record of page 1)
      cursor_payload = {
        updated_at: mid.updated_at.iso8601(6),
        id: mid.id
      }
      cursor = Base64.urlsafe_encode64(cursor_payload.to_json, padding: false)

      # Page 2 using cursor
      get "/enrichments", params: { doi: doi.doi, cursor: cursor }

      expect(response).to have_http_status(:ok)
      ids2 = json["data"].map { |h| h["id"] }
      expect(ids2).to eq([older.id])
    end

    it "returns 400 for an invalid cursor" do
      doi = create(:doi)
      create_enrichment!(doi: doi.doi, updated_at: Time.utc(2026, 1, 29, 10, 0, 0))

      get "/enrichments", params: { doi: doi.doi, cursor: "not-a-valid-base64" }

      expect(response).to have_http_status(:bad_request)
    end

    it "builds next link with client-id param name (hyphen) when paginating by client_id" do
      stub_const("EnrichmentsController::PAGE_SIZE", 2)

      provider = create(:provider)
      client = create(:client, provider: provider, symbol: "#{provider.symbol}.DATACITE.TEST")
      doi = create(:doi, client: client)

      t = Time.utc(2026, 1, 29, 10, 0, 0)
      create_enrichment!(doi: doi.doi, updated_at: t + 2.seconds)
      create_enrichment!(doi: doi.doi, updated_at: t + 1.second)

      get "/enrichments", params: { client_id: client.symbol }

      expect(response).to have_http_status(:ok)
      next_link = json.dig("links", "next")
      expect(next_link).to be_present
      expect(next_link).to include("client-id=#{CGI.escape(client.symbol)}")
      expect(next_link).to include("cursor=")
    end
  end
end
