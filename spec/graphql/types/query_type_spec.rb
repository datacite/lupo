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

  describe "query providers", elasticsearch: true do
    let!(:providers) { create_list(:provider, 3) }

    before do
      Provider.import
      sleep 1
    end

    let(:query) do
      %(query {
        providers {
          totalCount
          nodes {
            id
            name
          }
        }
      })
    end

    it "returns all providers" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "providers", "totalCount")).to eq(3)
      expect(response.dig("data", "providers", "nodes").length).to eq(3)
      expect(response.dig("data", "providers", "nodes", 0, "id")).to eq(providers.first.uid)
    end
  end

  describe "find provider", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "TESTC") }
    let(:client) { create(:client, provider: provider, software: "dataverse") }
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:prefix) { create(:prefix) }
    let!(:provider_prefixes) { create_list(:provider_prefix, 3, provider: provider) }

    before do
      Provider.import
      Client.import
      Doi.import
      Prefix.import
      ProviderPrefix.import
      sleep 2
    end

    let(:query) do
      %(query {
        provider(id: "testc") {
          id
          name
          country {
            name
          }
          clients {
            totalCount
            years {
              id
              count
            }
            software {
              id
              count
            }
            nodes {
              id
              name
              software
              datasets {
                totalCount
              }
            }
          }
          prefixes {
            totalCount
            years {
              id
              count
            }
            nodes {
              name
            }
          }
        }
      })
    end

    it "returns provider" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "provider", "id")).to eq(provider.uid)
      expect(response.dig("data", "provider", "name")).to eq("My provider")
      expect(response.dig("data", "provider", "country")).to eq("name"=>"Germany")

      expect(response.dig("data", "provider", "clients", "totalCount")).to eq(1)
      expect(response.dig("data", "provider", "clients", "years")).to eq([{"count"=>1, "id"=>"2020"}])
      expect(response.dig("data", "provider", "clients", "software")).to eq([{"count"=>1, "id"=>"dataverse"}])
      expect(response.dig("data", "provider", "clients", "nodes").length).to eq(1)
      client1 = response.dig("data", "provider", "clients", "nodes", 0)
      expect(client1.fetch("id")).to eq(client.uid)
      expect(client1.fetch("name")).to eq(client.name)
      expect(client1.fetch("software")).to eq("dataverse")
      expect(client1.dig("datasets", "totalCount")).to eq(1)

      expect(response.dig("data", "provider", "prefixes", "totalCount")).to eq(3)
      expect(response.dig("data", "provider", "prefixes", "years")).to eq([{"count"=>3, "id"=>"2020"}])
      expect(response.dig("data", "provider", "prefixes", "nodes").length).to eq(3)
      prefix1 = response.dig("data", "provider", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(provider_prefixes.first.prefix_id)
    end
  end

  describe "query clients", elasticsearch: true do
    let!(:clients) { create_list(:client, 3) }

    before do
      Client.import
      sleep 1
    end

    let(:query) do
      %(query {
        clients {
          totalCount
          nodes {
            id
            name
            alternateName
          }
        }
      })
    end

    it "returns all clients" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "clients", "totalCount")).to eq(3)
      expect(response.dig("data", "clients", "nodes").length).to eq(3)

      client1 = response.dig("data", "clients", "nodes", 0)
      expect(client1.fetch("id")).to eq(clients.first.uid)
      expect(client1.fetch("name")).to eq(clients.first.name)
      expect(client1.fetch("alternateName")).to eq(clients.first.alternate_name)
    end
  end

  describe "find client", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "TESTC") }
    let(:client) { create(:client, symbol: "TESTC.TESTC", alternate_name: "ABC", provider: provider) }
    let!(:doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:prefix) { create(:prefix) }
    let!(:client_prefixes) { create_list(:client_prefix, 3, client: client) }

    before do
      Provider.import
      Client.import
      Doi.import
      Prefix.import
      ClientPrefix.import
      sleep 2
    end

    let(:query) do
      %(query {
        client(id: "testc.testc") {
          id
          name
          alternateName
          datasets {
            totalCount
          }
          prefixes {
            totalCount
            years {
              id
              count
            }
            nodes {
              name
            }
          }
        }
      })
    end

    it "returns client" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "client", "id")).to eq(client.uid)
      expect(response.dig("data", "client", "name")).to eq("My data center")
      expect(response.dig("data", "client", "alternateName")).to eq("ABC")

      expect(response.dig("data", "client", "datasets", "totalCount")).to eq(1)

      expect(response.dig("data", "client", "prefixes", "totalCount")).to eq(3)
      expect(response.dig("data", "client", "prefixes", "years")).to eq([{"count"=>3, "id"=>"2020"}])
      expect(response.dig("data", "client", "prefixes", "nodes").length).to eq(3)
      prefix1 = response.dig("data", "client", "prefixes", "nodes", 0)
      expect(prefix1.fetch("name")).to eq(client_prefixes.first.prefix_id)
    end
  end

  describe "find client with citations", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "TESTR") }
    let(:client) { create(:client, symbol: "TESTR.TESTR", provider: provider) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
      }])
    }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
    let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

    before do
      Provider.import
      Client.import
      Event.import
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        client(id: "testr.testr") {
          id
          name
          citationCount
          works {
            totalCount
            years {
              title
              count
            }
            resourceTypes {
              title
              count
            }
            nodes {
              id
              titles {
                title
              }
              citationCount
            }
          }
        }
      })
    end

    it "returns client information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "client", "id")).to eq("testr.testr")
      expect(response.dig("data", "client", "name")).to eq("My data center")
      expect(response.dig("data", "client", "citationCount")).to eq(0)
      expect(response.dig("data", "client", "works", "totalCount")).to eq(3)
      expect(response.dig("data", "client", "works", "years")).to eq([{"count"=>3, "title"=>"2011"}])
      expect(response.dig("data", "client", "works", "resourceTypes")).to eq([{"count"=>3, "title"=>"Dataset"}])
      expect(response.dig("data", "client", "works", "nodes").length).to eq(3)

      work = response.dig("data", "client", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig("citationCount")).to eq(0)
    end
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

    it "returns all datasets" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "datasets", "totalCount")).to eq(3)
      expect(response.dig("data", "datasets", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "datasets", "nodes").length).to eq(3)
      expect(response.dig("data", "datasets", "nodes", 0, "id")).to eq(datasets.first.identifier)
    end
  end

  describe "query person", elasticsearch: true, vcr: true do
    let(:client) { create(:client) }
    let(:doi) { create(:doi, client: client, aasm_state: "findable", creators:
      [{
        "familyName" => "Garza",
        "givenName" => "Kristian",
        "name" => "Garza, Kristian",
        "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
        "nameType" => "Personal",
      }])
    }
    let(:source_doi) { create(:doi, client: client, aasm_state: "findable") }
    let(:source_doi2) { create(:doi, client: client, aasm_state: "findable") }
    let!(:citation_event) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi.doi}", relation_type_id: "is-referenced-by", occurred_at: "2015-06-13T16:14:19Z") }
    let!(:citation_event2) { create(:event_for_datacite_crossref, subj_id: "https://doi.org/#{doi.doi}", obj_id: "https://doi.org/#{source_doi2.doi}", relation_type_id: "is-referenced-by", occurred_at: "2016-06-13T16:14:19Z") }

    before do
      Client.import
      Event.import
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        person(id: "https://orcid.org/0000-0003-3484-6875") {
          id
          name
          givenName
          familyName
          citationCount
          viewCount
          downloadCount
          works {
            totalCount
            years {
              title
              count
            }
            resourceTypes {
              title
              count
            }
            nodes {
              id
              titles {
                title
              }
              citationCount
            }
          }
        }
      })
    end

    it "returns person information" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "person", "id")).to eq("https://orcid.org/0000-0003-3484-6875")
      expect(response.dig("data", "person", "name")).to eq("K. J. Garza")
      expect(response.dig("data", "person", "citationCount")).to eq(0)
      expect(response.dig("data", "person", "works", "totalCount")).to eq(1)
      expect(response.dig("data", "person", "works", "years")).to eq([{"count"=>1, "title"=>"2011"}])
      expect(response.dig("data", "person", "works", "resourceTypes")).to eq([{"count"=>1, "title"=>"Dataset"}])
      expect(response.dig("data", "person", "works", "nodes").length).to eq(1)

      work = response.dig("data", "person", "works", "nodes", 0)
      expect(work.dig("titles", 0, "title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(work.dig("citationCount")).to eq(0)
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
            works {
              totalCount
              years {
                title
                count
              }
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
