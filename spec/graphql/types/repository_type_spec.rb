
# frozen_string_literal: true

require "rails_helper"

describe RepositoryType do
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


  describe "query repositories" do
    before :all do
      @search_query =
        "
        fragment facetFields on Facet {
          id
          title
          count
        }
        query (
            $query: String,
            $certificate: String,
            $software: String
            $repositoryType: String
            $isOpen: String
            $isDisciplinary: String
            $isCertified: String
            $hasPid: String
            $subject: String
            $subjectId: String
          ){
          repositories(
              first: 10,
              query: $query,
              certificate: $certificate,
              software: $software,
              subject: $subject,
              subjectId: $subjectId,
              isOpen: $isOpen,
              isDisciplinary: $isDisciplinary,
              isCertified: $isCertified,
              hasPid: $hasPid,
              repositoryType: $repositoryType
            ) {
            nodes {
              uid
              name
              re3dataDoi
              software
              repositoryType
              certificate
            }
            totalCount
            pageInfo {
              endCursor
              hasNextPage
            }
            software { ...facetFields }
            repositoryTypes { ...facetFields }
            certificates { ...facetFields }
            members { ...facetFields }

          }
        }
        "

      ReferenceRepository.import(force: true)
      VCR.use_cassette("ReferenceRepositoryType/re3Data/set_of_10_re3_repositories") do
        create(:reference_repository, re3doi:  "10.17616/R3BW5R")
        create(:reference_repository, re3doi:  "10.17616/r3vg6n")
        create(:reference_repository, re3doi:  "10.17616/r37m1j")
        create(:reference_repository, re3doi:  "10.17616/R3003X")
        create(:reference_repository, re3doi:  "10.17616/R31NJCHT")
        create(:reference_repository, re3doi:  "10.17616/R3NC74")
        create(:reference_repository, re3doi:  "10.17616/R3106C")
        create(:reference_repository, re3doi:  "10.17616/R31NJN59")
        create(:reference_repository, re3doi:  "10.17616/R31NJMTE")
        @client = create(:client, re3data_id:  "10.17616/R31NJMJX")
        sleep 2
        @facet_response = LupoSchema.execute(@search_query).as_json
      end
    end

    after :all do
      Rails.logger.level = :fatal
      ReferenceRepository.destroy_all
    end

    let(:search_query) { @search_query }

    it "returns several repositories" do
      response = @facet_response
      expect(response.dig("data", "repositories", "totalCount")).to eq(10)
    end

    it "returns software facets" do
      response = @facet_response
      expect(
        response.dig("data", "repositories", "software"),
      ).to eq([
        { "count" => 4, "id" => "other", "title" => "other" },
        { "count" => 3, "id" => "unknown", "title" => "unknown" },
        { "count" => 2, "id" => "dataverse", "title" => "DataVerse" }
      ])
    end

    it "returns certificate facets" do
      response = @facet_response
      expect(
        response.dig("data", "repositories", "certificates"),
      ).to eq([
        { "count" => 4, "id" => "CoreTrustSeal", "title" => "Core Trust Seal" },
        { "count" => 1, "id" => "DINI Certificate", "title" => "Dini Certificate" },
        { "count" => 1, "id" => "DSA", "title" => "Dsa" }
      ])
    end

    it "returns repositoryType facets" do
      response = @facet_response
      expect(
        response.dig("data", "repositories", "repositoryTypes"),
      ).to eq([
        { "count" => 9, "id" => "disciplinary", "title" => "Disciplinary" },
        { "count" => 5, "id" => "institutional", "title" => "Institutional" }
      ])
    end

    it "returns members facets" do
      response = @facet_response
      expect(
        response.dig("data", "repositories", "members"),
      ).to eq([
        { "count" => 1, "id" => @client.provider.symbol.downcase, "title" => "My provider" },
      ])
    end

    it "specifies a general query" do
      response = LupoSchema.execute(
        search_query,
        variables: { query: "data" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(9)
    end

    it "filters based on certificate" do
      response = LupoSchema.execute(
        search_query,
        variables: { certificate: "CoreTrustSeal" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(4)
    end

    it "filters based on software" do
      response = LupoSchema.execute(
        search_query,
        variables: { software: "DataVerse" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(2)
    end

    it "filters based on repository type" do
      response = LupoSchema.execute(
        search_query,
        variables: { repositoryType: "institutional" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(5)
    end

    it "filter based on isOpen" do
      response = LupoSchema.execute(
        search_query,
        variables: { isOpen: "true" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(9)
    end

    it "filter based on isDisciplinary" do
      response = LupoSchema.execute(
        search_query,
        variables: { isDisciplinary: "true" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(9)
    end

    it "filter based on isCertified" do
      response = LupoSchema.execute(
        search_query,
        variables: { isCertified: "true" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(5)
    end

    it "filter based on hasPid" do
      response = LupoSchema.execute(
        search_query,
        variables: { hasPid: "true" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(8)
    end

    it "filter based on subjectId" do
      response = LupoSchema.execute(
        search_query,
        variables: { subjectId: "3.+" }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(5)
    end

    it "filters for FAIRS FAIR" do
      response = LupoSchema.execute(
        search_query,
          variables: {
              subject: "",
              isOpen: "true",
              hasPid: "true",
              isCertified: "true"
          }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(5)
    end

    it "filters for Enabling FAIR Data Project" do
      response = LupoSchema.execute(
        search_query,
          variables: {
            subjectId: "34",
            isOpen: "true",
            hasPid: "true",
            isCertified: ""
          }
      ).as_json
      expect(response.dig("data", "repositories", "totalCount")).to eq(4)
    end
  end

  describe "query single repository" do
    before :all do
      id_query = "query($id: ID!){
          repository(id: $id) {
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
            works {
              totalCount
            }
          }

      }"
      VCR.use_cassette("ReferenceRepositoryType/re3Data/R3BW5R") do
        @ref_repo2 = create(:reference_repository, re3doi:  "10.17616/R3BW5R")
      end

      sleep 2
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo2.re3doi }).as_json
      @repo = response.dig("data", "repository")
    end

    after :all do
      Rails.logger.level = :fatal
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
          "doi"
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

  describe "find repository" do
    let(:id_query) do
      "query($id: ID!){
        repository(id: $id) {
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
        ReferenceRepository.import
        sleep 2
      end
    end

    after :all do
      Rails.logger.level = :fatal
      Client.destroy_all
      Provider.destroy_all
      ReferenceRepository.destroy_all
    end

    before :each do
    end

    it "by client_id" do
      response = LupoSchema.execute(id_query, variables: { id: @client.symbol }).as_json
      expect(response.dig("data", "repository", "clientId")).to eq(@client.symbol)
      expect(response.dig("data", "repository", "name")).to eq(@client.name)
    end

    it "by re3doi" do
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo.re3doi }).as_json
      expect(response.dig("data", "repository", "re3dataDoi")).to eq(@ref_repo.re3doi)
      expect(response.dig("data", "repository", "name")).to eq(@client.name)
    end

    it "by uid" do
      response = LupoSchema.execute(id_query, variables: { id: @ref_repo.uid }).as_json
      expect(response.dig("data", "repository", "uid")).to eq(@ref_repo.uid)
      expect(response.dig("data", "repository", "name")).to eq(@client.name)
    end

    it "error if none found" do
      response = LupoSchema.execute(id_query, variables: { id: "XXX" }).as_json
      expect(response.dig("errors", 0, "message")).to eq(
        "Cannot return null for non-nullable field Query.repository"
      )
    end
  end

  describe "find repository and related works/dois" do
    let(:works_query) do
      "query($id: ID!){
        repository(id: $id) {
          uid
          name
          re3dataDoi
          clientId
          citationCount
          works {
            totalCount
          }
        }
      }"
    end

    before :all do
      VCR.use_cassette("ReferenceRepositoryType/related_works_citations", allow_playback_repeats: true) do
        @provider = create(:provider, symbol: "TESTR")
        @client = create(:client, symbol: "TESTR.TESTR", provider: @provider)
        @client2 = create(:client, symbol: "TESTR.TESTZ", provider: @provider)
        @ref_repo = create(:reference_repository, client_id: @client.symbol, re3doi:  "10.17616/R3XS37")
        @doi = create(
          :doi,
          client: @client,
          aasm_state: "findable",
          creators: [
            {
              "familyName" => "Garza",
              "givenName" => "Kristian",
              "name" => "Garza, Kristian",
              "nameIdentifiers" => [
                {
                  "nameIdentifier" => "https://orcid.org/0000-0003-3484-6875",
                  "nameIdentifierScheme" => "ORCID",
                  "schemeUri" => "https://orcid.org",
                },
              ],
              "nameType" => "Personal",
            },
          ],
        )
        @source_doi = create(:doi, client: @client, aasm_state: "findable")
        @source_doi2 = create(:doi, client: @client, aasm_state: "findable")
        create(
          :event_for_datacite_crossref,
          subj_id: "https://doi.org/#{@doi.doi}",
          obj_id: "https://doi.org/#{@source_doi.doi}",
          relation_type_id: "is-referenced-by",
          occurred_at: "2015-06-13T16:14:19Z",
        )
        create(
          :event_for_datacite_crossref,
          subj_id: "https://doi.org/#{@doi.doi}",
          obj_id: "https://doi.org/#{@source_doi2.doi}",
          relation_type_id: "is-referenced-by",
          occurred_at: "2016-06-13T16:14:19Z",
        )
        Provider.import(force: true)
        Client.import(force: true)
        Doi.import(force: true)
        ReferenceRepository.import(force: true)

        sleep 2
      end
    end

    after :all do
      Rails.logger.level = :fatal
      ReferenceRepository.destroy_all
      Client.destroy_all
      Provider.destroy_all
      Doi.destroy_all
      Event.destroy_all
    end

    it "returns repository with works total count" do
      response = LupoSchema.execute(works_query, variables: { id: @ref_repo.uid }).as_json
      expect(response.dig("data", "repository", "works", "totalCount")).to eq(3)
    end

    it "returns repository with works citation count" do
      response = LupoSchema.execute(works_query, variables: { id: @ref_repo.uid }).as_json
      expect(response.dig("data", "repository", "citationCount")).to eq(2)
    end
  end
end
