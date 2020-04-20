require "rails_helper"

describe PreprintType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query preprints", elasticsearch: true do
    let!(:preprints) { create_list(:doi, 2, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Preprint" }, aasm_state: "findable") }
    let!(:posted_contents) { create_list(:doi, 2, types: { "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent" }, agency: "Crossref", aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        preprints {
          totalCount
          registrationAgencies {
            title
            count
          }
          nodes {
            id
            type
          }
        }
      })
    end

    it "returns all preprints" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "preprints", "totalCount")).to eq(4)
      expect(response.dig("data", "preprints", "registrationAgencies")).to eq([{"count"=>2, "title"=>"Crossref"}, {"count"=>2, "title"=>"DataCite"}])
      expect(response.dig("data", "preprints", "nodes").length).to eq(4)
      expect(response.dig("data", "preprints", "nodes", 0, "id")).to eq(preprints.first.identifier)
      expect(response.dig("data", "preprints", "nodes", 0, "type")).to eq("Preprint")
    end
  end

  describe "query preprints by person", elasticsearch: true do
    let!(:preprints) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent" }, aasm_state: "findable") }
    let!(:preprint) { create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "PostedContent" }, aasm_state: "findable", creators:
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
        preprints(userId: "https://orcid.org/0000-0003-1419-2405") {
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

    it "returns preprints" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "preprints", "totalCount")).to eq(3)
      expect(response.dig("data", "preprints", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "preprints", "nodes").length).to eq(3)
      expect(response.dig("data", "preprints", "nodes", 0, "id")).to eq(preprints.first.identifier)
    end
  end
end
