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
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(datasets.first.identifier)
    end
  end

  describe "query datasets by person", elasticsearch: true do
    let!(:datasets) { create_list(:doi, 3, aasm_state: "findable") }
    let!(:dataset) { create(:doi, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
      }])
    }
    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets(userId: "https://orcid.org/0000-0003-1419-2405") {
          totalCount
          years {
            id
            count
          }
          nodes {
            id
          }
        }
      })
    end

    it "returns datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(datasets.first.identifier)
    end
  end

  describe "query with citations", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
    let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
          nodes {
            id
            citationCount
            citationsOverTime {
              year
              total
            }
            citations {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "citationCount")).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "citationsOverTime")).to eq([{"total"=>1, "year"=>2015}, {"total"=>1, "year"=>2016}])
      expect(response.dig("data", "datasets", "nodes", 0, "citations", "totalCount")).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "citations", "nodes").length).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "citations", "nodes", 0)).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with references", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, aasm_state: "findable") }
    let(:target_doi2) { create(:doi, aasm_state: "findable") }
    let!(:reference_event) { create(:event_for_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi.doi}", relation_type_id: "references") }
    let!(:reference_event2) { create(:event_for_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi2.doi}", relation_type_id: "references") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
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
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json
      
      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "referenceCount")).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "references", "totalCount")).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "references", "nodes").length).to eq(2)
      expect(response.dig("data", "datasets", "nodes", 0, "references", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with versions", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:target_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:version_event) { create(:event_for_datacite_versions, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi.doi}") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
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
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 1, "versionCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "versions", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "versions", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "versions", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with version of", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of_events) { create(:event_for_datacite_version_of, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
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
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json
      puts response
      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 1, "versionOfCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 0, "versionOf", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "versionOf", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "versionOf", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with parts", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:target_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_events) { create(:event_for_datacite_parts, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{target_doi.doi}", relation_type_id: "has-part") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
          nodes {
            id
            partCount
            parts {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 1, "partCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "parts", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "parts", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "parts", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end

  describe "query with part of", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let!(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:part_of_events) { create(:event_for_datacite_part_of, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-part-of") }

    before do
      Doi.import
      Event.import
      sleep 2
    end

    let(:query) do
      %(query {
        datasets {
          totalCount
          nodes {
            id
            partOfCount
            partOf {
              totalCount
              nodes {
                id
                publicationYear
              }
            }
          }
        }
      })
    end

    it "returns all datasets with counts" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 1, "partOfCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "partOf", "totalCount")).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "partOf", "nodes").length).to eq(1)
      expect(response.dig("data", "datasets", "nodes", 1, "partOf", "nodes").first).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.doi.downcase}", "publicationYear"=>2011)
    end
  end
end
