# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe "DOI batches", type: :request do
  let(:provider) { create(:provider, symbol: "DATACITE") }
  let(:client) { create(:client, provider: provider, symbol: "DATACITE.BATCH") }
  let(:prefix) { create(:prefix, uid: "10.14454") }
  let!(:client_prefix) { create(:client_prefix, client: client, prefix: prefix) }
  let(:bearer) do
    Client.generate_token(
      role_id: "client_admin",
      uid: client.symbol,
      provider_id: provider.symbol.downcase,
      client_id: client.symbol.downcase,
      password: client.password,
    )
  end
  let(:headers) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json",
      "HTTP_AUTHORIZATION" => "Bearer #{bearer}",
    }
  end

  let(:create_resources) do
    [
      {
        type: "dois",
        attributes: {
          doi: "10.14454/batch-1",
          url: "https://example.org/1",
        },
      },
      {
        type: "dois",
        attributes: {
          doi: "10.14454/batch-2",
          url: "https://example.org/2",
        },
      },
    ]
  end

  describe "POST /dois with an array" do
    it "accepts the batch and enqueues processing" do
      expect do
        post "/dois", { data: create_resources }, headers
      end.to have_enqueued_job(DoiBatchProcessJob)

      expect(last_response.status).to eq(202), last_response.body
      expect(json.dig("data", "type")).to eq("doi-batches")
      expect(json.dig("data", "attributes", "totalCount")).to eq(2)
      expect(last_response.headers["Location"]).to end_with(
        "/doi-batches/#{json.dig('data', 'id')}",
      )

      batch = DoiBatch.find_by!(uuid: json.dig("data", "id"))
      expect(batch.operation).to eq("create")
      expect(batch.items.pluck(:doi)).to eq(
        %w[10.14454/batch-1 10.14454/batch-2],
      )
    end

    it "rejects empty and oversized batches" do
      post "/dois", { data: [] }, headers
      expect(last_response.status).to eq(400)

      oversized = Array.new(1_001) { create_resources.first }
      post "/dois", { data: oversized }, headers
      expect(last_response.status).to eq(400)
    end

    it "rejects the entire batch when an item is unauthorized" do
      unauthorized = create_resources.deep_dup
      unauthorized.last[:attributes][:doi] = "10.99999/not-allowed"

      expect do
        post "/dois", { data: unauthorized }, headers
      end.not_to change(DoiBatch, :count)

      expect(last_response.status).to eq(403), last_response.body
    end

    it "preallocates generated DOI values" do
      post "/dois",
           {
             data: [
               {
                 type: "dois",
                 attributes: {
                   prefix: "10.14454",
                   url: "https://example.org/generated",
                 },
               },
             ],
           },
           headers

      expect(last_response.status).to eq(202), last_response.body
      item = DoiBatch.last.items.first
      expect(item).to be_generated_doi
      expect(item.doi).to start_with("10.14454/")
      expect(item.payload.dig("attributes", "doi")).to eq(item.doi)
    end
  end

  describe "PATCH /dois with an array" do
    let!(:doi) do
      create(
        :doi,
        type: "DataciteDoi",
        client: client,
        doi: "10.14454/batch-update",
      )
    end

    it "accepts updates and upserts" do
      resources = [
        {
          type: "dois",
          id: doi.doi,
          attributes: { url: "https://example.org/updated" },
        },
        {
          type: "dois",
          id: "10.14454/batch-upsert",
          attributes: { url: "https://example.org/upsert" },
        },
      ]

      patch "/dois", { data: resources }, headers

      expect(last_response.status).to eq(202), last_response.body
      expect(DoiBatch.last.operation).to eq("update")
      expect(DoiBatch.last.items.pluck(:doi)).to eq(
        %w[10.14454/batch-update 10.14454/batch-upsert],
      )
    end

    it "rejects transfer mode" do
      patch "/dois",
            {
              data: [
                {
                  type: "dois",
                  id: doi.doi,
                  attributes: { mode: "transfer" },
                },
              ],
            },
            headers

      expect(last_response.status).to eq(400)
      expect(DoiBatch.count).to eq(0)
    end
  end

  describe "GET /doi-batches/:id" do
    let!(:batch) do
      DoiBatch.create!(
        operation: "create",
        submitted_by: client.symbol.downcase,
        role_id: "client_admin",
        client_id: client.symbol.downcase,
        provider_id: provider.symbol.downcase,
        total_count: 1,
      )
    end
    let!(:item) do
      batch.items.create!(
        position: 0,
        doi: "10.14454/batch-1",
        payload: create_resources.first,
      )
    end

    it "returns status and paginated item results" do
      get "/doi-batches/#{batch.uuid}", {}, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "pendingCount")).to eq(1)

      get "/doi-batches/#{batch.uuid}/items", {}, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", 0, "attributes", "doi")).to eq(
        "10.14454/batch-1",
      )
    end

    it "filters item results by status" do
      item.update!(
        status: "failed",
        response_status: 422,
        result_errors: [{ source: "url", title: "URL is not valid" }],
      )

      get "/doi-batches/#{batch.uuid}/items?status=failed", {}, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "attributes", "errors")).to eq(
        [{ "source" => "url", "title" => "URL is not valid" }],
      )
    end

    it "denies a different client account" do
      other_client =
        create(:client, provider: provider, symbol: "DATACITE.OTHER")
      other_bearer =
        Client.generate_token(
          role_id: "client_admin",
          uid: other_client.symbol,
          provider_id: provider.symbol.downcase,
          client_id: other_client.symbol.downcase,
          password: other_client.password,
        )
      other_headers =
        headers.merge("HTTP_AUTHORIZATION" => "Bearer #{other_bearer}")

      get "/doi-batches/#{batch.uuid}", {}, other_headers

      expect(last_response.status).to eq(403), last_response.body
    end
  end

  describe "compressed batch requests" do
    let(:compressed_headers) do
      headers.merge(
        "CONTENT_TYPE" => "application/gzip",
        "HTTP_CONTENT_ENCODING" => "gzip",
      )
    end

    it "accepts a gzip-compressed POST array" do
      body = ActiveSupport::Gzip.compress({ data: create_resources }.to_json)

      post "/dois", body, compressed_headers

      expect(last_response.status).to eq(202), last_response.body
    end

    it "accepts a gzip-compressed PATCH array" do
      doi =
        create(
          :doi,
          type: "DataciteDoi",
          client: client,
          doi: "10.14454/compressed-update",
        )
      body =
        ActiveSupport::Gzip.compress(
          {
            data: [
              {
                type: "dois",
                id: doi.doi,
                attributes: { url: "https://example.org/compressed" },
              },
            ],
          }.to_json,
        )

      patch "/dois", body, compressed_headers

      expect(last_response.status).to eq(202), last_response.body
    end
  end
end
