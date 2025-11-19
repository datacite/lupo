# frozen_string_literal: true

require "rails_helper"

describe ServiceType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query services", elasticsearch: true do
    let(:provider) { create(:provider, symbol: "DATACITE") }
    let(:client) do
      create(:client, symbol: "DATACITE.SERVICES", provider: provider)
    end
    let!(:services) do
      create_list(
        :doi,
        3,
        aasm_state: "findable",
        client: client,
        types: { "resourceTypeGeneral" => "Service" },
        titles: [{ "title" => "Test Service" }],
        subjects: [
          {
            "subject": "FOS: Computer and information sciences",
            "schemeUri": "http://www.oecd.org/science/inno/38235147.pdf",
            "subjectScheme": "Fields of Science and Technology (FOS)",
          },
          { "subject": "Instrument", "subjectScheme": "PidEntity" },
        ],
        geo_locations: [
          {
            "geoLocationPoint" => {
              "pointLatitude" => "49.0850736",
              "pointLongitude" => "-123.3300992",
            },
            "geoLocationPlace" => "Munich, Germany",
          },
        ],
      )
    end

    before do
      Provider.import
      Client.import
      Doi.import
      sleep 3
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        services(pidEntity: \"instrument\") {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          published {
            id
            title
            count
          }
          pidEntities {
            id
            title
            count
          }
          fieldsOfScience {
            id
            title
            count
          }
          nodes {
            id
            doi
            identifiers {
              identifier
              identifierType
            }
            types {
              resourceTypeGeneral
            }
            titles {
              title
            }
            fieldsOfScience {
              id
              name
            }
            descriptions {
              description
              descriptionType
            }
            geolocations {
              geolocationPlace
              geolocationPoint {
                pointLongitude
                pointLatitude
              }
            }
          }
        }
      }"
    end

    it "returns services" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "services", "totalCount")).to eq(3)
      expect(response.dig("data", "services", "pidEntities")).to eq(
        [{ "count" => 3, "id" => "instrument", "title" => "Instrument" }],
      )
      expect(response.dig("data", "services", "fieldsOfScience")).to eq(
        [
          {
            "count" => 3,
            "id" => "computer_and_information_sciences",
            "title" => "Computer and information sciences",
          },
        ],
      )
      expect(
        Base64.urlsafe_decode64(
          response.dig("data", "services", "pageInfo", "endCursor"),
        ).
          split(",", 2).
          last,
      ).to eq(@dois.last.uid)
      expect(
        response.dig("data", "services", "pageInfo", "hasNextPage"),
      ).to be false
      expect(response.dig("data", "services", "published")).to eq(
        [{ "count" => 3, "id" => "2011", "title" => "2011" }],
      )
      expect(response.dig("data", "services", "nodes").length).to eq(3)

      service = response.dig("data", "services", "nodes", 0)
      expect(service.fetch("id")).to eq(@dois.first.identifier)
      expect(service.fetch("doi")).to eq(@dois.first.uid)
      expect(service.fetch("identifiers")).to eq(
        [{ "identifier" => "pk-1234", "identifierType" => "publisher ID" }],
      )
      expect(service.fetch("types")).to eq("resourceTypeGeneral" => "Service")
      expect(service.dig("titles", 0, "title")).to eq("Test Service")
      expect(service.dig("descriptions", 0, "description")).to eq(
        "Data from: A new malaria agent in African hominids.",
      )
      expect(service.dig("fieldsOfScience")).to eq(
        [
          {
            "id" => "computer_and_information_sciences",
            "name" => "Computer and information sciences",
          },
        ],
      )
      expect(service.dig("geolocations", 0, "geolocationPlace")).to eq(
        "Munich, Germany",
      )
      expect(service.dig("geolocations", 0, "geolocationPoint")).to eq(
        "pointLatitude" => 49.0850736, "pointLongitude" => -123.3300992,
      )
    end
  end
end
