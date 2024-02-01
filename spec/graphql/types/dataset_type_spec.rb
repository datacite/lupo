# frozen_string_literal: true

require "rails_helper"

describe DatasetType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query datasets", elasticsearch: true do
    let!(:datasets) { create_list(:doi, 3, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets(first: 20) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            schemaOrg
          }
        }
      }"
    end

    it "returns all datasets" do
      response = LupoSchema.execute(**{query: query})
      response = response.as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(
        @dois.first.identifier,
      )
      expect(
        JSON.parse(response.dig("data", "datasets", "nodes", 0, "schemaOrg"))[
          "@context"
        ],
      ).to eq("http://schema.org")
      expect(
        JSON.parse(response.dig("data", "datasets", "nodes", 0, "schemaOrg"))[
          "@type"
        ],
      ).to eq("Dataset")
    end
  end

  describe "query datasets by person", elasticsearch: true do
    let!(:datasets) do
      create_list(
        :doi,
        3,
        aasm_state: "findable",
        creators: [
          {
            "nameType": "Personal",
            "name": "Renaud, François",
            "givenName": "François",
            "familyName": "Renaud",
            "nameIdentifiers": [
              {
                "nameIdentifier": "https://orcid.org/0000-0003-1419-2405",
                "nameIdentifierScheme": "ORCID",
                "schemeUri": "https://orcid.org",
              },
            ],
            "affiliation": [
              {
                "name": "DataCite",
                "affiliationIdentifier": "https://ror.org/04wxnsj81",
                "affiliationIdentifierScheme": "ROR",
              },
            ],
          },
          {
            "nameType": "Organizational",
            "name": "Crossref",
            "nameIdentifiers": [
              {
                "nameIdentifier": "https://ror.org/02twcfp32",
                "nameIdentifierScheme": "ROR",
                "schemeUri": "https://ror.org",
              },
            ],
          },
        ],
      )
    end
    let!(:dataset) do
      create(
        :doi,
        doi: "10.14454/4k3m-nyvg",
        url: "https://example.org",
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
        identifiers: [
          { "identifier" => "pk-1235", "identifierType" => "publisher ID" },
          { "identifier" => "https://example.org", "identifierType" => "URL" },
          { "identifier" => "10.14454/4k3m-nyvg", "identifierType" => "DOI" },
        ],
      )
    end
    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      "query {
        datasets(userId: \"https://orcid.org/0000-0003-3484-6875\") {
          totalCount
          published {
            id
            title
            count
          }
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            identifiers {
              identifier
              identifierType
            }
            creators {
              id
              type
              name
            }
          }
        }
      }"
    end

    it "returns datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      # expect(Base64.urlsafe_decode64(response.dig("data", "datasets", "pageInfo", "endCursor")).split(",", 2).last).to eq(@dois[2].uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(@dois.first.identifier)
      expect(response.dig("data", "datasets", "nodes", 0, "creators")).to eq(
        [
          {
            "id" => "https://orcid.org/0000-0003-3484-6875",
            "name" => "Garza, Kristian",
            "type" => "Person",
          },
        ],
      )
      expect(response.dig("data", "datasets", "nodes", 0, "identifiers")).to eq(
        [{ "identifier" => "pk-1235", "identifierType" => "publisher ID" }],
      )
    end
  end

  describe "query datasets by field of science", elasticsearch: true do
    let!(:datasets) { create_list(:doi, 3, aasm_state: "findable") }
    let!(:dataset) do
      create(
        :doi,
        aasm_state: "findable",
        subjects: [
          {
            "subject": "FOS: Computer and information sciences",
            "schemeUri": "http://www.oecd.org/science/inno/38235147.pdf",
            "subjectScheme": "Fields of Science and Technology (FOS)",
          },
        ],
      )
    end
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        datasets(fieldOfScience: \"computer_and_information_sciences\") {
          totalCount
          published {
            id
            title
            count
          }
          fieldsOfScience {
            id
            title
            count
          }
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            fieldsOfScience {
              id
              name
            }
          }
        }
      }"
    end

    it "returns datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "published")).to eq(
        [{ "count" => 1, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "datasets", "fieldsOfScience")).to eq(
        [
          {
            "count" => 1,
            "id" => "computer_and_information_sciences",
            "title" => "Computer and information sciences",
          },
        ],
      )
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(dataset.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(
        dataset.identifier,
      )
      expect(
        response.dig("data", "datasets", "nodes", 0, "fieldsOfScience"),
      ).to eq(
        [
          {
            "id" => "computer_and_information_sciences",
            "name" => "Computer and information sciences",
          },
        ],
      )
    end
  end

  describe "query datasets by field of science no facets", elasticsearch: true do
    let!(:datasets) { create_list(:doi, 3, aasm_state: "findable") }
    let!(:dataset) do
      create(
        :doi,
        aasm_state: "findable",
        subjects: [
          {
            "subject": "FOS: Computer and information sciences",
            "schemeUri": "http://www.oecd.org/science/inno/38235147.pdf",
            "subjectScheme": "Fields of Science and Technology (FOS)",
          },
        ],
      )
    end
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      "query {
        datasets(fieldOfScience: \"computer_and_information_sciences\", facetCount: 0) {
          totalCount
          published {
            id
            title
            count
          }
          fieldsOfScience {
            id
            title
            count
          }
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            fieldsOfScience {
              id
              name
            }
          }
        }
      }"
    end

    it "returns datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "published")).to be_empty
      expect(response.dig("data", "datasets", "fieldsOfScience")).to be_empty
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(dataset.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(
        dataset.identifier,
      )
      expect(
        response.dig("data", "datasets", "nodes", 0, "fieldsOfScience"),
      ).to eq(
        [
          {
            "id" => "computer_and_information_sciences",
            "name" => "Computer and information sciences",
          },
        ],
      )
    end
  end

  describe "query with citations", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) do
      create(
        :event_for_datacite_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2015-06-13T16:14:19Z",
      )
    end
    let!(:citation_event2) do
      create(
        :event_for_datacite_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi2.doi}",
        relation_type_id: "is-referenced-by",
        occurred_at: "2016-06-13T16:14:19Z",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 3
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            citationCount
            citationsOverTime {
              year
              total
            }
            citations(resourceTypeId: \"Dataset\") {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    xit "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 0, "citationCount")).to eq(2)
      #   expect(response.dig("data", "datasets", "nodes", 0, "citationsOverTime")).to eq([{"total"=>1, "year"=>2015}, {"total"=>1, "year"=>2016}])
      expect(
        response.dig("data", "datasets", "nodes", 0, "citations", "totalCount"),
      ).to eq(2)
      expect(
        response.dig("data", "datasets", "nodes", 0, "citations", "nodes").
          length,
      ).to eq(2)
      #   expect(response.dig("data", "datasets", "nodes", 0, "citations", "nodes", 0)).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.uid}", "publicationYear"=>2011)
    end
  end

  describe "query with views", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:usage_event) do
      create(
        :event_for_datacite_usage,
        obj_id: "https://doi.org/#{source_doi.doi}",
        occurred_at: "2015-06-13T16:14:19Z",
      )
    end
    let!(:usage_event2) do
      create(
        :event_for_datacite_usage,
        obj_id: "https://doi.org/#{source_doi2.doi}",
        occurred_at: "2016-06-13T16:14:19Z",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            viewCount
            viewsOverTime {
              yearMonth
              total
            }
          }
        }
      }"
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(2)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(2)
      # expect(response.dig("data", "datasets", "nodes", 0, "viewCount")).to be > 1
      # expect(response.dig("data", "datasets", "nodes", 0, "viewsOverTime").length).to be >= 1
      # expect(response.dig("data", "datasets", "nodes", 0, "viewsOverTime").first.dig('yearMonth')).not_to be_nil
      #   expect(response.dig("data", "datasets", "nodes", 0, "citations", "totalCount")).to eq(2)
      #   expect(response.dig("data", "datasets", "nodes", 0, "citations", "nodes").length).to eq(2)
      #   expect(response.dig("data", "datasets", "nodes", 0, "citations", "nodes", 0)).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.uid}", "publicationYear"=>2011)
    end
  end

  describe "query with references", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, aasm_state: "findable") }
    let(:target_doi2) { create(:doi, aasm_state: "findable") }
    let!(:reference_event) do
      create(
        :event_for_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{target_doi.doi}",
        relation_type_id: "references",
      )
    end
    let!(:reference_event2) do
      create(
        :event_for_crossref,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{target_doi2.doi}",
        relation_type_id: "references",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            referenceCount
            references {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 0, "referenceCount")).to eq(2)
      # expect(response.dig("data", "datasets", "nodes", 0, "references", "totalCount")).to eq(2)
      # expect(response.dig("data", "datasets", "nodes", 0, "references", "nodes").length).to eq(2)
      # expect(response.dig("data", "datasets", "nodes", 0, "references", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.uid}", "publicationYear"=>2011)
    end
  end

  describe "query with versions", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:target_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:version_event) do
      create(
        :event_for_datacite_versions,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{target_doi.doi}",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            versionCount
            versions {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 1, "versionCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versions", "totalCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versions", "nodes").length).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versions", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with version of", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of_events) do
      create(
        :event_for_datacite_version_of,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi.doi}",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 3
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            versionOfCount
            versionOf {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 1, "versionOfCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versionOf", "totalCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versionOf", "nodes").length).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "versionOf", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.uid}", "publicationYear"=>2011)
    end
  end

  describe "query with parts", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:target_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_events) do
      create(
        :event_for_datacite_parts,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{target_doi.doi}",
        relation_type_id: "has-part",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            partCount
            parts {
              totalCount
              pageInfo {
                endCursor
                hasNextPage
              }
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 0, "partCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 0, "parts", "totalCount")).to eq(1)
      # expect(Base64.urlsafe_decode64(response.dig("data", "datasets", "nodes", 1, "parts", "pageInfo", "endCursor")).split(",", 2).last).to eq(@dois.last.uid)
      # expect(response.dig("data", "datasets", "nodes", 0, "parts", "pageInfo", "hasNextPage")).to be false
      # expect(response.dig("data", "datasets", "nodes", 0, "parts", "nodes").length).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 0, "parts", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.uid}", "publicationYear"=>2011)
    end
  end

  describe "query with part of", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of_events) do
      create(
        :event_for_datacite_part_of,
        subj_id: "https://doi.org/#{doi.doi}",
        obj_id: "https://doi.org/#{source_doi.doi}",
        relation_type_id: "is-part-of",
      )
    end

    before do
      Doi.import
      Event.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        datasets {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            partOfCount
            partOf {
              totalCount
              pageInfo {
                endCursor
                hasNextPage
              }
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      }"
    end

    xit "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "datasets", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "datasets", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      # expect(response.dig("data", "datasets", "nodes", 1, "partOfCount")).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "partOf", "totalCount")).to eq(1)
      # expect(Base64.urlsafe_decode64(response.dig("data", "datasets", "nodes", 1, "partOf", "pageInfo", "endCursor")).split(",", 2).last).to eq(@dois.last.uid)
      # expect(response.dig("data", "datasets", "nodes", 1, "partOf", "pageInfo", "hasNextPage")).to be false
      # expect(response.dig("data", "datasets", "nodes", 1, "partOf", "nodes").length).to eq(1)
      # expect(response.dig("data", "datasets", "nodes", 1, "partOf", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end
end
