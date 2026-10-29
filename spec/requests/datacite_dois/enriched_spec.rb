# frozen_string_literal: true

require "rails_helper"
include Passwordable

describe DataciteDoisController, type: :request, vcr: true, prefix_pool_size: 11 do
  def import_doi_index
    DataciteDoi.import
    DataciteDoi.__elasticsearch__.client.indices.refresh(index: DataciteDoi.index_name)
  end

  def refresh_enriched_doi_index
    EnrichedDoi.__elasticsearch__.client.indices.refresh(index: EnrichedDoi.index_name)
  end

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

  context "GET /dois/[id] with enriched=true", elasticsearch: true, prefix_pool_size: 4 do
    let!(:enrichment) { create(:enrichment) }
    let!(:enrichment_newer) do
      create(:enrichment,
        doi: enrichment.doi,
        created_at: enrichment.created_at + 1.hour,
        enriched_value: {
          "name" => "Arslan, M.",
          "nameType" => "Personal",
          "givenName" => "M.",
          "familyName" => "Arslan",
          "nameIdentifiers" => [],
          "affiliation" => [
            {
              "name" => "Nigeria Maritime University",
              "identifier" => "https://ror.org/04peych45",
              "identifierScheme" => "ROR",
            },
          ],
        }
      )
    end
    let!(:doi) { create(:doi, doi: enrichment.doi, client: client, aasm_state: "findable", creators: [{
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
      }]) }
    let!(:invalid_enrichment) { create(:enrichment, field: "types", action: "update", original_value: {
        "resourceTypeGeneral": "Dataset",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }, enriched_value: {
        "resourceTypeGeneral": "InvalidResourceType",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }) }
    let!(:doi_with_invalid_enrichment) { create(:doi, doi: invalid_enrichment.doi, client: client, aasm_state: "findable") }

    it "returns the original value at /dois/[id]" do
      get "/dois/#{doi.doi}", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
      expect(json.dig("data", "attributes", "creators", 0)).to eq({
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
        "nameIdentifiers" => [],
      })
      expect(doi.creators.first["affiliation"]).to eq([])
    end

    it "returns enriched doi at /dois/[id]?enriched=true with newest enrichment applied" do
      get "/dois/#{doi.doi}?enriched=true&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "doi")).to eq(doi.doi.downcase)
      expect(json.dig("data", "attributes", "creators", 0)).to eq(enrichment_newer.enriched_value)
      expect(json.dig("data", "relationships", "enrichments", "data").count).to eq(2)
      expect(doi.creators.first["affiliation"]).to eq([])
    end

    it "returns the original value at /dois/[id] when enrichment is invalid" do
      get "/dois/#{doi_with_invalid_enrichment.doi}", nil, headers
      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "doi")).to eq(doi_with_invalid_enrichment.doi.downcase)
      expect(json.dig("data", "attributes", "types", "resourceTypeGeneral")).to eq("Dataset")
      expect(json.dig("data", "relationships", "enrichments")).to be_nil
    end

    it "returns the original value at /dois/[id]?enriched=true when enrichment is invalid" do
      get "/dois/#{doi_with_invalid_enrichment.doi}?enriched=true&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data", "attributes", "doi")).to eq(doi_with_invalid_enrichment.doi.downcase)
      expect(json.dig("data", "attributes", "types", "resourceTypeGeneral")).to eq("Dataset")
      expect(json.dig("data", "relationships", "enrichments", "data").count).to eq(0)
    end
  end

  context "GET /dois with enriched=true", elasticsearch: true, prefix_pool_size: 4 do
    let!(:enrichment) { create(:enrichment) }
    let!(:doi) { create(:doi, doi: enrichment.doi, client: client, aasm_state: "findable", creators: [{
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
      }]) }
    let(:doi_with_invalid_url) do
      create(:doi, doi: "10.14454/invalid", client: client, aasm_state: "findable", creators: [{
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
      }]).tap do |doi_record|
        doi_record.update_column(:url, "http://example.com/invalid with space")
      end
    end
    let!(:enrichment_for_doi_with_invalid_url) { create(:enrichment, doi: doi_with_invalid_url.doi) }
    let(:doi_with_invalid_enrichment) do
      create(:doi, doi: "10.14454/invalid-enrichment", client: client, aasm_state: "findable")
    end
    let!(:enrichment_for_doi_with_invalid_enrichment) do
      create(:enrichment, doi: doi_with_invalid_enrichment.doi, field: "types", action: "update", original_value: {
        "resourceTypeGeneral": "Dataset",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }, enriched_value: {
        "resourceTypeGeneral": "InvalidResourceType",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      })
    end

    before do
      IndexJobDoiRegistration.perform_now(doi)
      IndexJobDoiRegistration.perform_now(doi_with_invalid_url)
      IndexJobDoiRegistration.perform_now(doi_with_invalid_enrichment)
      EnrichedDoiIndexJob.perform_now(doi_with_invalid_url.doi)
      import_doi_index
      refresh_enriched_doi_index
    end

    it "returns the original value at /dois" do
      get "/dois?query=doi:#{doi.doi}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data").size).to eq(1)
      expect(json.dig("data", 0, "attributes", "doi")).to eq(doi.doi.downcase)
      expect(json.dig("data", 0, "attributes", "creators", 0)).to eq({
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
        "nameIdentifiers" => [],
      })
      expect(doi.creators.first["affiliation"]).to eq([])
    end

    it "returns enriched doi at /dois?enriched=true" do
      get "/dois?query=doi:#{doi.doi}&enriched=true&affiliation=true", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("data").size).to eq(1)
      expect(json.dig("data", 0, "attributes", "doi")).to eq(doi.doi.downcase)
      expect(json.dig("data", 0, "attributes", "creators", 0)).to eq(enrichment.enriched_value)
      expect(json.dig("data", 0, "relationships", "enrichments", "data").count).to eq(1)
      expect(doi.creators.first["affiliation"]).to eq([])
    end

    context "with cursor pagination" do
      let!(:additional_dois) { create_list(:doi, 4, client: client, aasm_state: "findable") }

      before do
        import_doi_index
        refresh_enriched_doi_index
      end

      it "returns enriched dois with cursor" do
        get "/dois?enriched=true&page[cursor]&page[size]=2", nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"].size).to eq(2)
        expect(json.dig("links", "next")).to be_present
        expect(json.dig("links", "next")).to include("enriched=true")

        cursor = Rack::Utils.parse_query(json.dig("links", "next").split("?", 2).last).fetch("page[cursor]", nil)
        expect(cursor).to be_present
        expect { Base64.urlsafe_decode64(cursor) }.not_to raise_error

        next_link_absolute = Addressable::URI.parse(json.dig("links", "next"))
        next_link = next_link_absolute.path + "?" + next_link_absolute.query

        get next_link, nil, headers

        expect(last_response.status).to eq(200)
        expect(json["data"]).not_to be_empty
      end
    end

    context "when the doi title is updated" do
      let(:updated_titles) { [{ "title" => "Updated Title" }] }

      before do
        doi.update!(titles: updated_titles)
        IndexJobDoiRegistration.perform_now(doi)
        import_doi_index
        refresh_enriched_doi_index
      end

      it "returns the updated title at /dois" do
        get "/dois?query=doi:#{doi.doi}", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", 0, "attributes", "titles")).to eq(updated_titles)
      end

      it "returns the updated title at /dois?enriched=true" do
        get "/dois?query=doi:#{doi.doi}&enriched=true&affiliation=true", nil, headers

        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi.doi.downcase)
        expect(json.dig("data", 0, "attributes", "titles")).to eq(updated_titles)
        expect(json.dig("data", 0, "attributes", "creators", 0)).to eq(enrichment.enriched_value)
        expect(json.dig("data", 0, "relationships", "enrichments", "data").count).to eq(1)
      end
    end

    context "when a doi record has an invalid url" do
      it "returns the original value at /dois" do
        get "/dois?query=doi:#{doi_with_invalid_url.doi}", nil, headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi_with_invalid_url.doi.downcase)
        expect(json.dig("data", 0, "attributes", "creators")).to eq([{
          "name" => "Arslan, M.",
          "givenName" => "M.",
          "familyName" => "Arslan",
          "affiliation" => [],
          "nameIdentifiers" => [],
        }])
      end

      it "returns the enriched value at /dois?enriched=true" do
        get "/dois?query=doi:#{doi_with_invalid_url.doi}&enriched=true&affiliation=true", nil, headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi_with_invalid_url.doi.downcase)
        expect(json.dig("data", 0, "attributes", "creators")).to eq([
          enrichment_for_doi_with_invalid_url.enriched_value
        ])
        expect(json.dig("data", 0, "relationships", "enrichments", "data").count).to eq(1)
      end
    end

    context "when a doi record has an invalid enrichment" do
      it "returns the original value at /dois" do
        get "/dois?query=doi:#{doi_with_invalid_enrichment.doi}", nil, headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi_with_invalid_enrichment.doi.downcase)
        expect(json.dig("data", 0, "attributes", "types", "resourceTypeGeneral")).to eq("Dataset")
        expect(json.dig("data", 0, "relationships", "enrichments")).to be_nil
      end

      it "returns the original value at /dois?enriched=true" do
        get "/dois?query=doi:#{doi_with_invalid_enrichment.doi}&enriched=true&affiliation=true", nil, headers
        expect(last_response.status).to eq(200)
        expect(json.dig("data").size).to eq(1)
        expect(json.dig("data", 0, "attributes", "doi")).to eq(doi_with_invalid_enrichment.doi.downcase)
        expect(json.dig("data", 0, "attributes", "types", "resourceTypeGeneral")).to eq("Dataset")
        expect(json.dig("data", 0, "relationships", "enrichments", "data").count).to eq(0)
      end
    end
  end

  describe "GET /dois with filters and aggregations on enrichment_source_ids", elasticsearch: true do
    let!(:affiliation_enrichment) { create(:enrichment, source_id: "10.1234/affiliation-enrichment") }
    let!(:doi_with_affiliation_enrichment) { create(:doi, doi: affiliation_enrichment.doi, client: client, aasm_state: "findable", creators: [{
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
      }]) }
    let(:doi_with_resource_type_enrichment) do
      create(:doi, doi: "10.14454/rte", client: client, aasm_state: "findable")
    end
    let!(:resource_type_enrichment) do
      create(:enrichment, source_id: "10.1234/rte-enrichment", doi: doi_with_resource_type_enrichment.doi, field: "types", action: "update", original_value: {
        "resourceTypeGeneral": "Dataset",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }, enriched_value: {
        "resourceTypeGeneral": "JournalArticle",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      })
    end

    before do
      IndexJobDoiRegistration.perform_now(doi_with_affiliation_enrichment)
      IndexJobDoiRegistration.perform_now(doi_with_resource_type_enrichment)
      # EnrichedDoiIndexJob.perform_now(doi_with_resource_type_enrichment.doi)
      # EnrichedDoiIndexJob.perform_now(doi_with_affiliation_enrichment.doi)
      import_doi_index
      refresh_enriched_doi_index
    end

    it "enrichmentSourceIds facet returns meta.enrichmentSourceIds when enriched=true" do
      get "/dois?enriched=true&disable-facets=false&facets=enrichmentSourceIds", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "enrichmentSourceIds")).to eq([
        {
          "id" => "10.1234/affiliation-enrichment",
          "title" => "10.1234/affiliation-enrichment",
          "count" => 1,
        },
        {
          "id" => "10.1234/rte-enrichment",
          "title" => "10.1234/rte-enrichment",
          "count" => 1
        }
      ])
    end

    it "enrichment-source-id filter returns a list filtered by enrichment_source_ids when enriched=true" do
      get "/dois?enriched=true&enrichment-source-id=#{affiliation_enrichment.source_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "id").downcase).to eq(doi_with_affiliation_enrichment.doi.downcase)
    end

    it "query=enrichment_source_ids: filter returns a list filtered by enrichment_source_ids when enriched=true" do
      get "/dois?enriched=true&query=enrichment_source_ids:#{resource_type_enrichment.source_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(1)
      expect(json.dig("data", 0, "id").downcase).to eq(doi_with_resource_type_enrichment.doi.downcase)
    end

    it "enrichmentSourceIds facet returns empty meta.enrichmentSourceIds when enriched= is not set" do
      get "/dois?disable-facets=false&facets=enrichmentSourceIds", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "enrichmentSourceIds")).to eq([])
    end

    it "enrichment-source-id filter returns an empty list when enriched= is not set" do
      get "/dois?enrichment-source-id=#{affiliation_enrichment.source_id}", nil, headers

      expect(last_response.status).to eq(200)
      expect(json.dig("meta", "total")).to eq(0)
    end
  end
end
