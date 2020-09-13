require "rails_helper"

describe WorkType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "find work", elasticsearch: true do
    let!(:work) { create(:doi, aasm_state: "findable", container:
      { "type" => "Journal", 
        "issue" => "9", 
        "title" => "Inorganica Chimica Acta", 
        "volume" => "362", 
        "lastPage" => "3180", 
        "firstPage" => "3172", 
        "identifier" => "0020-1693", 
        "identifierType" => "ISSN" }) }

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
          container {
            identifier
            identifierType
            title
          }
          bibtex
          xml
          schemaOrg
        }
      })
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      expect(response.dig("data", "work", "container")).to eq("identifier"=>"0020-1693", "identifierType"=>"ISSN", "title"=>"Inorganica Chimica Acta")
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

      schema_org = JSON.parse(response.dig("data", "work", "schemaOrg"))
      expect(schema_org["@id"]).to eq("https://doi.org/#{work.doi.downcase}")
      expect(schema_org["name"]).to eq("Data from: A new malaria agent in African hominids.")

      doc = Nokogiri::XML(response.dig("data", "work", "xml"), nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(work.doi)
      expect(doc.at_css("titles").content).to eq("Data from: A new malaria agent in African hominids.")
    end
  end

  describe "find work crossref", elasticsearch: true, vcr: true do
    let!(:work) { create(:doi, doi: "10.1038/nature12373", agency: "crossref", aasm_state: "findable", titles: [
      { "title" => "Nanometre-scale thermometry in a living cell" }]) }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        work(id: "https://doi.org/#{work.doi}") {
          id
          titles {
            title
          }
          url
          contentUrl
        }
      })
    end

    it "returns work" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "work", "id")).to eq("https://handle.test.datacite.org/#{work.doi.downcase}")
      expect(response.dig("data", "work", "titles")).to eq([{"title"=>"Nanometre-scale thermometry in a living cell"}])
      expect(response.dig("data", "work", "url")).to eq(work.url)
      expect(response.dig("data", "work", "contentUrl")).to eq("https://dash.harvard.edu/bitstream/1/12285462/1/Nanometer-Scale%20Thermometry.pdf")
    end
  end

  describe "find work not found", elasticsearch: true do
    let(:query) do
      %(query {
        work(id: "https://doi.org/10.14454/xxx") {
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
          container {
            identifier
            identifierType
            title
          }
          bibtex
          xml
          schemaOrg
        }
      })
    end

    it "returns error" do
      response = LupoSchema.execute(query).as_json
      
      expect(response.dig("data")).to be_nil
      expect(response.dig("errors")).to eq([{"locations"=>[{"column"=>9, "line"=>2}], "message"=>"Record not found", "path"=>["work"]}])
    end
  end

  describe "query works", elasticsearch: true, vcr: true do
    let(:query) do
      %(query($first: Int, $cursor: String) {
        works(first: $first, after: $cursor) {
          totalCount
          totalCountFromCrossref
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
      @works = Doi.gql_query(nil, page: { cursor: [], size: 10 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "totalCountFromCrossref")).to eq(116990655)
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

  describe "query works by registration agency", elasticsearch: true, vcr: true do
    let(:query) do
      %(query($first: Int, $cursor: String, $registrationAgency: String) {
        works(first: $first, after: $cursor, registrationAgency: $registrationAgency) {
          totalCount
          totalCountFromCrossref
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
            registered
            language {
              id
              name
            }
            registrationAgency {
              id
              name
            }
          }
        }
      })
    end
    
    let!(:works) { create_list(:doi, 10, aasm_state: "findable", language: "nl", agency: "datacite") }
    let!(:work) { create(:doi, aasm_state: "findable", language: "de", agency: "crossref") }

    before do
      Doi.import
      sleep 2
      @works = Doi.gql_query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil, registrationAgency: "datacite" }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "totalCountFromCrossref")).to eq(116990655)
      expect(response.dig("data", "works", "registrationAgencies")).to eq([{"count"=>10, "id"=>"datacite", "title"=>"DataCite"}])
      expect(response.dig("data", "works", "languages")).to eq([{"count"=>10, "id"=>"nl", "title"=>"Dutch"}])
      # expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "registered")).to start_with(@works[0].registered[0..9])
      expect(response.dig("data", "works", "nodes", 0, "language")).to eq("id"=>"nl", "name"=>"Dutch")
      expect(response.dig("data", "works", "nodes", 0, "registrationAgency")).to eq("id"=>"datacite", "name"=>"DataCite")
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
            registered
            subjects {
              subject
              subjectScheme
            }
            rights {
              rights
              rightsUri
              rightsIdentifier
            }
          }
        }
      })
    end
    
    let!(:works) { create_list(:doi, 10, aasm_state: "findable", agency: "datacite", subjects:
      [{
        "subject" => "Computer and information sciences"
      }])
    }
    let!(:work) { create(:doi, aasm_state: "findable", agency: "crossref", rights_list: []) }

    before do
      Doi.import
      sleep 2
      @works = Doi.gql_query(nil, page: { cursor: [], size: 11 }).results.to_a
    end

    it "returns all works" do
      response = LupoSchema.execute(query, variables: { first: 4, cursor: nil, license: "cc0-1.0" }).as_json

      expect(response.dig("data", "works", "totalCount")).to eq(10)
      expect(response.dig("data", "works", "licenses")).to eq([{"count"=>10, "id"=>"cc0-1.0", "title"=>"CC0-1.0"}])
      # expect(Base64.urlsafe_decode64(response.dig("data", "works", "pageInfo", "endCursor")).split(",", 2).last).to eq(@works[3].uid)
      expect(response.dig("data", "works", "pageInfo", "hasNextPage")).to be true
      expect(response.dig("data", "works", "nodes").length).to eq(4)
      expect(response.dig("data", "works", "nodes", 0, "id")).to eq(@works[0].identifier)
      expect(response.dig("data", "works", "nodes", 0, "registered")).to start_with(@works[0].registered[0..9])
      expect(response.dig("data", "works", "nodes", 0, "subjects")).to eq([{"subject"=>"Computer and information sciences", "subjectScheme"=>nil}, {"subject"=>"FOS: Computer and information sciences", "subjectScheme"=>"Fields of Science and Technology (FOS)"}])
      expect(response.dig("data", "works", "nodes", 0, "rights")).to eq([{"rights"=>"Creative Commons Zero v1.0 Universal",
        "rightsIdentifier"=>"cc0-1.0",
        "rightsUri"=>"https://creativecommons.org/publicdomain/zero/1.0/legalcode"}])
    end
  end
end
