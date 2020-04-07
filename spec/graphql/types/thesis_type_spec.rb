require "rails_helper"

describe ThesisType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query theses", elasticsearch: true do
    let!(:theses) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" }, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        theses {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all theses" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "theses", "totalCount")).to eq(3)
      expect(response.dig("data", "theses", "nodes").length).to eq(3)
      expect(response.dig("data", "theses", "nodes", 0, "id")).to eq(theses.first.identifier)
    end
  end

  describe "query theses by person", elasticsearch: true do
    let!(:theses) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" }, aasm_state: "findable") }
    let!(:thesis) { create(:doi, types: { "resourceTypeGeneral" => "Text", "resourceType" => "Thesis" }, aasm_state: "findable", creators:
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
        theses(userId: "https://orcid.org/0000-0003-1419-2405") {
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

    it "returns theses" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "theses", "totalCount")).to eq(3)
      expect(response.dig("data", "theses", "years")).to eq([{"count"=>3, "id"=>"2011"}])
      expect(response.dig("data", "theses", "nodes").length).to eq(3)
      expect(response.dig("data", "theses", "nodes", 0, "id")).to eq(theses.first.identifier)
    end
  end
end
