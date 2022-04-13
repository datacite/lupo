
# frozen_string_literal: true

require "rails_helper"

describe ReferenceRepositoryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:uid).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
    it { is_expected.to have_field(:clientId).of_type(types.ID) }
    it { is_expected.to have_field(:re3dataDoi).of_type(types.ID) }
    it { is_expected.to have_field(:name).of_type("String!") }
    it { is_expected.to have_field(:alternateName).of_type("[String!]") }
    it { is_expected.to have_field(:description).of_type("String") }
    it { is_expected.to have_field(:url).of_type("Url") }
    it { is_expected.to have_field(:re3dataUrl).of_type("Url") }
    it { is_expected.to have_field(:software).of_type("[String!]") }
    it { is_expected.to have_field(:repositoryType).of_type("[String!]") }
    it { is_expected.to have_field(:certificate).of_type("[String!]") }
    it { is_expected.to have_field(:language).of_type("[String!]") }
    it { is_expected.to have_field(:providerType).of_type("[String!]") }
    it { is_expected.to have_field(:pidSystem).of_type("[String!]") }
    it { is_expected.to have_field(:dataAccess).of_type("[TextRestriction!]") }
    it { is_expected.to have_field(:dataUpload).of_type("[TextRestriction!]") }
    it { is_expected.to have_field(:contact).of_type("[String!]") }
    it { is_expected.to have_field(:subject).of_type("[DefinedTerm!]") }
  end


  describe "query referenceRepositories", elastic: true, vcr: true do
    let(:search_query) do
      "query {
        referenceRepositories(first: 10) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }"
    end
    before :all do
      VCR.use_cassette("ReferenceRepositoryType/re3Data/several") do
        create(:reference_repository, re3doi:  "10.17616/R3BW5R")
        create(:reference_repository, re3doi:  "10.17616/r3vg6n")
        create(:reference_repository, re3doi:  "10.17616/r37m1j")
        sleep 2
      end
    end

    after :all do
      Rails.logger.level = :fatal
      ReferenceRepository.destroy_all
    end

    it "returns several repositories" do
      response = LupoSchema.execute(search_query).as_json
      expect(response.dig("data", "referenceRepositories", "totalCount")).to eq(3)
    end


  end
  describe "query single referenceRepository", elastic: true, vcr: true do
    before :all do
      id_query = "query($id: ID!){
          referenceRepository(id: $id) {
            uid
            name
            alternateName
            re3dataDoi
            clientId
            description
            certificate
            providerType
            contact
            pidSystem
            dataAccess {
             restriction { text }
             type
            }
            dataUpload {
             restriction { text }
             type
            }
            language
            software
          }

      }"
      VCR.use_cassette("ReferenceRepositoryType/re3Data/R3BW5R") do
        @ref_repo2 = create(:reference_repository, re3doi:  "10.17616/R3BW5R")
      end

      sleep 2
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo2.re3doi }).as_json
      @repo = response.dig("data", "referenceRepository")
    end

    after :all do
      ReferenceRepository.destroy_all
    end

    it "returns list of alternativeNames" do
      expect(@repo.fetch("alternateName")).to eq(
        ["SSDA Dataverse\r\nUCLA Library Data Science Center"],
      )
    end

    it "returns description" do
      expect(@repo.fetch("description")).to start_with(
        "The Social Science Data Archive is still active and maintained as part of the UCLA Library",
      )
    end

    it "returns list of certificates" do
      expect(@repo.fetch("certificate")).to be_empty
    end

    it "returns list of providerTypes" do
      expect(@repo.fetch("providerType")).to eq(
        [
          "dataProvider",
        ]
      )
    end

    it "returns list of contacts" do
      expect(@repo.fetch("contact")).to eq(
        [
          "datascience@ucla.edu",
        ],
      )
    end

    it "returns list of pidSystems" do
      expect(@repo.fetch("pidSystem")).to match_array(
        [
          "hdl",
          "DOI"
        ]
      )
    end

    it "returns list of dataAccess policies" do
      expect(@repo.fetch("dataAccess")).to match_array(
        [
            { "restriction" => nil, "type" => "restricted" },
            { "restriction" => nil, "type" => "open" }
        ]
      )
    end

    it "returns list of dataUpload policies" do
      expect(@repo.fetch("dataUpload")).to match_array(
        [
            { "restriction" => nil, "type" => "restricted" },
        ]
      )
    end

    it "returns list of languages" do
      expect(@repo.fetch("language")).to eq(
        [
          "eng"
        ]
      )
    end

    it "returns list of software" do
      expect(@repo.fetch("software")).to eq(
        [
          "DataVerse"
        ]
      )
    end
  end

  describe "find referenceRepository", elastic: true, vcr: true do

    let(:id_query) do
      "query($id: ID!){
        referenceRepository(id: $id) {
          uid
          name
          re3dataDoi
          clientId
        }
      }"
    end

    before :all do
      VCR.use_cassette("ReferenceRepositoryType/re3Data/R3XS37") do
        @client = create(:client)
        @ref_repo = create(:reference_repository, client_id: @client.symbol, re3doi:  "10.17616/R3XS37")
        sleep 2
      end
    end

    after :all do
      @client.delete
      ReferenceRepository.destroy_all
    end

    it "by client_id" do
      response = LupoSchema.execute(id_query, variables: { id: @client.symbol }).as_json
      expect(response.dig("data", "referenceRepository", "clientId")).to eq(@client.symbol)
      expect(response.dig("data", "referenceRepository", "name")).to eq(@client.name)
    end

    it "by re3doi" do
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo.re3doi }).as_json
      expect(response.dig("data", "referenceRepository", "re3dataDoi")).to eq(@ref_repo.re3doi)
      expect(response.dig("data", "referenceRepository", "name")).to eq(@client.name)
    end

    it "by uid" do
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo.hashid }).as_json
      expect(response.dig("data", "referenceRepository", "uid")).to eq(@ref_repo.hashid)
      expect(response.dig("data", "referenceRepository", "name")).to eq(@client.name)
    end

    it "error if none found" do
      response = LupoSchema.execute(id_query, variables: { id: "XXX" }).as_json
      expect(response.dig("errors", 0, "message")).to eq(
        "Cannot return null for non-nullable field Query.referenceRepository"
      )
    end
  end
end
