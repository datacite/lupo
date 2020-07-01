require "rails_helper"

describe WorkType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "find work", elasticsearch: true do
    let!(:work) { create(:doi, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        work(id: "https://doi.org/#{work.doi}") {
          id
          repository {
            id
            type
            name
          }
          member {
            id
            type
            name
          }
          bibtex
        }
      })
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      expect(response.dig("data", "work", "repository", "id")).to eq(work.client_id)
      expect(response.dig("data", "work", "repository", "name")).to eq(work.client.name)
      expect(response.dig("data", "work", "member", "id")).to eq(work.provider_id)
      expect(response.dig("data", "work", "member", "name")).to eq(work.provider.name)
      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      bibtex = BibTeX.parse(response.dig("data", "work", "bibtex")).to_a(quotes: '').first
      expect(bibtex[:bibtex_type].to_s).to eq("misc")
      expect(bibtex[:bibtex_key]).to eq("https://doi.org/#{work.doi.downcase}")
      expect(bibtex[:author]).to eq("Ollomo, Benjamin and Durand, Patrick and Prugnolle, Franck and Douzery, Emmanuel J. P. and Arnathau, Céline and Nkoghe, Dieudonné and Leroy, Eric and Renaud, François")
      expect(bibtex[:title]).to eq("Data from: A new malaria agent in African hominids.")
      expect(bibtex[:year]).to eq("2011")
    end
  end

  describe "query works", elasticsearch: true do
    let(:query) do
      %(query($first: Int, $cursor: String) {
        works(first: $first, after: $cursor) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            doi
          }
        }
      })
    end
    
    let!(:works) { create_list(:doi, 10, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
      @works = Doi.query(nil, page: { cursor: [], size: 10 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[0].identifier)
      end_cursor = response.dig("data", "works", "pageInfo", "endCursor")

      response = LupoSchema.execute(query, variables: { first: 4, cursor: end_cursor }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[7].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[4].identifier)
      end_cursor = response.dig("data", "works", "pageInfo", "endCursor")

      response = LupoSchema.execute(query, variables: { first: 4, cursor: end_cursor }).as_json
      
      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[9].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(2)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[8].identifier)
      end_cursor = response.dig("data", "works", "pageInfo", "endCursor")
    end
  end

  describe "query works by registration agency", elasticsearch: true do
    let(:query) do
      %(query($first: Int, $cursor: String, $registrationAgency: String) {
        works(first: $first, after: $cursor, registrationAgency: $registrationAgency) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          registrationAgencies {
            id
            title
            count
          }
          languages {
            id
            title
            count
          }
          nodes {
            id
            doi
          }
        }
      })
    end
    
    let!(:works) { create_list(:doi, 10, aasm_state: "findable", language: "fr", agency: "datacite") }
    let!(:work) { create(:doi, aasm_state: "findable", language: "de", agency: "crossref") }

    before do
      Doi.import
      sleep 2
      @works = Doi.query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil, registrationAgency: "datacite" }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "registrationAgencies")).to eq([{"count"=>10, "id"=>"datacite", "title"=>"DataCite"}])
      expect(response.dig("data", "works", "languages")).to eq([{"count"=>10, "id"=>"fr", "title"=>"French"}])
      # expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[0].identifier)
    end
  end

  describe "query works by license", elasticsearch: true do
    let(:query) do
      %(query($first: Int, $cursor: String, $license: String) {
        works(first: $first, after: $cursor, license: $license) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          licenses {
            id
            title
            count
          }
          nodes {
            id
            doi
          }
        }
      })
    end
    
    let!(:works) { create_list(:doi, 10, aasm_state: "findable", agency: "datacite") }
    let!(:work) { create(:doi, aasm_state: "findable", agency: "crossref", rights_list: []) }

    before do
      Doi.import
      sleep 2
      @works = Doi.query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil, license: "cc0-1.0" }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "licenses")).to eq([{"count"=>10, "id"=>"cc0-1.0", "title"=>"CC0-1.0"}])
      expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[0].identifier)
    end
  end
end
