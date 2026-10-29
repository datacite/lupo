# frozen_string_literal: true

require "rails_helper"

describe DataCatalogType, prefix_pool_size: 4 do
  describe "fields", skip_prefix_pool: true do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:name).of_type("String") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:contacts).of_type("[String!]") }
    it { is_expected.to have_field(:providerTypes).of_type("[String!]") }
    it { is_expected.to have_field(:pidSystems).of_type("[String!]") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:certificates).of_type("[DefinedTerm!]") }
    it { is_expected.to have_field(:subjects).of_type("[DefinedTerm!]") }
    it { is_expected.to have_field(:citationCount).of_type("Int") }
    it { is_expected.to have_field(:viewCount).of_type("Int") }
    it { is_expected.to have_field(:downloadCount).of_type("Int") }
    it { is_expected.to have_field(:dataAccesses).of_type("[TextRestriction!]") }
    it do
      is_expected.to have_field(:datasets).of_type("DatasetConnectionWithTotal")
    end
  end

  # describe "find data_catalog", elasticsearch: true, vcr: true do
  #   let(:client) { create(:client, re3data_id: "10.17616/r3xs37") }
  #   let(:doi) { create(:doi, client: client, aasm_state: "findable") }
  #   let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
  #   let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
  #   let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
  #   let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

  #   before do
  #     Client.import(refresh: true)
  #     Event.import(refresh: true)
  #     Doi.import(refresh: true)
  #   end

  #   let(:query) do
  #     %(query {
  #       dataCatalog(id: "https://doi.org/10.17616/r3xs37") {
  #         id
  #         name
  #         alternateName
  #         description
  #         certificates {
  #           termCode
  #           name
  #         }
  #         softwareApplication {
  #           name
  #           url
  #           softwareVersion
  #         }
  #         citationCount
  #         viewCount
  #         downloadCount
  #         datasets {
  #           totalCount
  #           years {
  #             title
  #             count
  #           }
  #           nodes {
  #             id
  #             titles {
  #               title
  #             }
  #             citationCount
  #           }
  #         }
  #       }
  #     })
  #   end

  #   it "returns data_catalog information" do
  #     response = LupoSchema.execute(query).as_json

  #     expect(response.dig("data", "dataCatalog", "id")).to eq("https://doi.org/10.17616/r3xs37")
  #     expect(response.dig("data", "dataCatalog", "name")).to eq("PANGAEA")
  #     expect(response.dig("data", "dataCatalog", "alternateName")).to eq(["Data Publisher for Earth and Environmental Science"])
  #     expect(response.dig("data", "dataCatalog", "description")).to start_with("The information system PANGAEA is operated as an Open Access library")
  #     expect(response.dig("data", "dataCatalog", "certificates")).to eq([{"termCode"=>nil, "name"=>"CoreTrustSeal"}])
  #     expect(response.dig("data", "dataCatalog", "softwareApplication")).to eq([{"name"=>"other", "url"=>nil, "softwareVersion"=>nil}])
  #     expect(response.dig("data", "dataCatalog", "citationCount")).to eq(0)
  #     # TODO should be 1
  #     expect(response.dig("data", "dataCatalog", "datasets", "totalCount")).to eq(1)
  #     # expect(response.dig("data", "funder", "works", "years")).to eq([{"count"=>1, "title"=>"2011"}])
  #     # expect(response.dig("data", "funder", "works", "resourceTypes")).to eq([{"count"=>1, "title"=>"Dataset"}])
  #     # expect(response.dig("data", "funder", "works", "nodes").length).to eq(1)

  #     work = response.dig("data", "dataCatalog", "datasets", "nodes", 0)
  #     expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
  #     expect(work.dig("citationCount")).to eq(0)
  #   end
  # end

  describe "query data_catalogs", skip_prefix_pool: true do
    let(:query) do
      "query {
        dataCatalogs(query: \"Dataverse\", first: 10) {
          totalCount
          pageInfo {
            hasNextPage
          }
          nodes {
            id
            name
          }
        }
      }"
    end

    it "returns an empty connection" do
      response = LupoSchema.execute(query).as_json

      expect(response["errors"]).to be_nil
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
      expect(response.dig("data", "dataCatalogs", "nodes")).to eq([])
      expect(
        response.dig("data", "dataCatalogs", "pageInfo", "hasNextPage"),
      ).to eq(false)
    end
  end

  describe "data_catalog", skip_prefix_pool: true do
    it "reports that the catalog record is not found" do
      response = LupoSchema.execute(
        %(query { dataCatalog(id: "https://doi.org/10.17616/r3xs37") { id } }),
      ).as_json

      expect(response.dig("errors", 0, "message")).to eq("Record not found")
    end
  end

  describe "more data_catalogs queries", skip_prefix_pool: true do
    let(:filtered_query) do
      "query($query: String, $subject: String, $open: String, $certified: String, $pid: String, $software: String, $disciplinary: String){
            dataCatalogs( query: $query, subject: $subject, open: $open, certified: $certified, pid: $pid, software: $software, disciplinary: $disciplinary){
              totalCount
        }
    }"
    end

    it "has no filters" do
      response = LupoSchema.execute(filtered_query, variables: { query: "" }).as_json
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
    end

    it "filters based on query" do
      response = LupoSchema.execute(filtered_query, variables: { query: "Dataverse" }).as_json
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
    end

    it "filters based on subject" do
      response = LupoSchema.execute(filtered_query, variables: { subject: "23" }).as_json
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
    end

    it "filters for FAIRS FAIR" do
      response = LupoSchema.execute(
        filtered_query,
          variables: {
              subject: "",
              open: "true",
              pid: "true",
              certified: "true"
          }
      ).as_json
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
    end

    it "filters for Enabling FAIR Data Project" do
      response = LupoSchema.execute(
        filtered_query,
          variables: {
              subject: "34",
              open: "true",
              pid: "true",
              certified: ""
          }
      ).as_json
      expect(response.dig("data", "dataCatalogs", "totalCount")).to eq(0)
    end
  end
end
