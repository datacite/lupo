require "rails_helper"

describe QueryType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:dataset).of_type("Dataset!") }
    it { is_expected.to have_field(:datasets).of_type("DatasetConnectionWithMeta!") }
    it { is_expected.to have_field(:publication).of_type("Publication!") }
    it { is_expected.to have_field(:publications).of_type("PublicationConnectionWithMeta!") }
    it { is_expected.to have_field(:service).of_type("Service!") }
    it { is_expected.to have_field(:services).of_type("ServiceConnectionWithMeta!") }
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

  describe "query person", elasticsearch: true, vcr: true do
    let!(:datasets) { create_list(:doi, 3, aasm_state: "findable", creators:
      [{
        "familyName" => "Fenner",
        "givenName" => "Martin",
        "name" => "Fenner, Martin",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-1419-2405", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
      }])
    }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        person(id: "https://orcid.org/0000-0003-1419-2405") {
          id
          name
          givenName
          familyName
          doiCount {
            title
            count
          }
          resourceTypeCount {
            title
            count
          }
          citationCount
          viewCount
          downloadCount
          works {
            totalCount
            nodes {
              id
              titles {
                title
              }
            }
          }
        }
      })
    end

    it "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq("https://orcid.org/0000-0003-1419-2405")
      expect(response.dig("data", "person", "name")).to eq("Martin Fenner")
      expect(response.dig("data", "person", "givenName")).to eq("Martin")
      expect(response.dig("data", "person", "doiCount")).to eq([{"count"=>3, "title"=>"2011"}])
      expect(response.dig("data", "person", "resourceTypeCount")).to eq([{"count"=>3, "title"=>"Dataset"}])
      expect(response.dig("data", "person", "works", "totalCount")).to eq(3)

      work = response.dig("data", "person", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
    end
  end

  describe "query people", elasticsearch: true, vcr: true do
    let(:query) do
      %(query {
        people(query: "Fenner") {
          totalCount
          nodes {
            id
            name
            givenName
            familyName
            doiCount {
              title
              count
            }
          }
        }
      })
    end

    it "returns people information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "people", "totalCount")).to eq(8)

      person = response.dig("data", "people", "nodes", 0)
      expect(person.fetch("id")).to eq("https://orcid.org/0000-0001-5508-9039")
      expect(person.fetch("name")).to eq("Andriel Evandro Fenner")
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
            creators {
              id
              name
              affiliation {
                id
                name
              }
            }
            citationCount
            citationsOverTime {
              year
              total
            }
            citations {
              id
              publicationYear
            }
          }
        }
      })
    end

    # it "returns all datasets with counts" do
    #   response = LupoSchema.execute(query).as_json

    #   expect(response.dig("data", "datasets", "totalCount")).to eq(3)
    #   expect(response.dig("data", "datasets", "nodes").length).to eq(3)
    #   expect(response.dig("data", "datasets", "nodes", 0, "creators").last).to eq("affiliation"=>[{"id"=>"https://ror.org/04wxnsj81", "name"=>"DataCite"}], "id"=>"https://orcid.org/0000-0003-1419-2405", "name"=>"Renaud, François")
    #   expect(response.dig("data", "datasets", "nodes", 0, "citationCount")).to eq(2)
    #   expect(response.dig("data", "datasets", "nodes", 0, "citationsOverTime")).to eq([{"total"=>1, "year"=>2015}, {"total"=>1, "year"=>2016}])
    #   expect(response.dig("data", "datasets", "nodes", 0, "citations").length).to eq(2)
    #   expect(response.dig("data", "datasets", "nodes", 0, "citations").first).to eq("id"=>"https://handle.test.datacite.org/#{source_doi.doi.downcase}", "publicationYear"=>2011)
    # end
  end

  describe "query with references", elasticsearch: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:target_doi2) { create(:doi, client: client, aasm_state: "findable") }
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
              id
              publicationYear
            }
          }
        }
      })
    end

    # it "returns all datasets with counts" do
    #   response = LupoSchema.execute(query).as_json

    #   expect(response.dig("data", "datasets", "totalCount")).to eq(3)
    #   expect(response.dig("data", "datasets", "nodes").length).to eq(3)
    #   expect(response.dig("data", "datasets", "nodes", 0, "referenceCount")).to eq(2)
    #   expect(response.dig("data", "datasets", "nodes", 0, "references").length).to eq(2)
    #   expect(response.dig("data", "datasets", "nodes", 0, "references").first).to eq("id"=>"https://handle.test.datacite.org/#{target_doi.doi.downcase}", "publicationYear"=>2011)
    # end
  end
end
