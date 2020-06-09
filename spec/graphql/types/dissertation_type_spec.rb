require "rails_helper"

describe DissertationType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query dissertations", elasticsearch: true do
    let!(:datacite_dissertations) { create_list(:doi, 2, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" }, aasm_state: "findable") }
    let!(:crossref_dissertations) { create_list(:doi, 2, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation" }, agency: "Crossref", aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
      @dois = Doi.query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      %(query {
        dissertations(registrationAgency: "datacite") {
          totalCount
          registrationAgencies {
            id
            title
            count
          }
          nodes {
            id
            registrationAgency
          }
        }
      })
    end

    it "returns all dissertations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dissertations", "totalCount")).to eq(4)
      expect(response.dig("data", "dissertations", "registrationAgencies")).to eq([{"count"=>2, "id"=>"crossref", "title"=>"Crossref"}, {"count"=>2, "id"=>"datacite", "title"=>"DataCite"}])
      expect(response.dig("data", "dissertations", "nodes").length).to eq(4)
      expect(response.dig("data", "dissertations", "nodes", 0, "id")).to eq(@dois.first.identifier)
      expect(response.dig("data", "dissertations", "nodes", 0, "registrationAgency")).to eq("DataCite")
    end
  end

  describe "query dissertations by person", elasticsearch: true do
    let!(:dissertations) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation" }, aasm_state: "findable") }
    let!(:dissertation) { create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Dissertation" }, aasm_state: "findable", creators:
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
      @dois = Doi.query(nil, page: { cursor: [], size: 4 }).results.to_a
    end

    let(:query) do
      %(query {
        dissertations(userId: "https://orcid.org/0000-0003-1419-2405") {
          totalCount
          published {
            id
            title
            count
          }
          nodes {
            id
          }
        }
      })
    end

    it "returns dissertations" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "dissertations", "totalCount")).to eq(3)
      expect(response.dig("data", "dissertations", "published")).to eq([{"count"=>3, "id"=>"2011", "title"=>"2011"}])
      expect(response.dig("data", "dissertations", "nodes").length).to eq(3)
      expect(response.dig("data", "dissertations", "nodes", 0, "id")).to eq(@dois.first.identifier)
    end
  end
end
