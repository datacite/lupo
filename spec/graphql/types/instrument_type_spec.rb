require "rails_helper"

describe InstrumentType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query instruments", elasticsearch: true do
    let!(:instruments) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Other", "resourceType" => "Instrument" }, aasm_state: "findable") }

    before do
      Doi.import
      sleep 2
    end

    let(:query) do
      %(query {
        instruments {
          totalCount
          nodes {
            id
          }
        }
      })
    end

    it "returns all instruments" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "instruments", "totalCount")).to eq(3)
      expect(response.dig("data", "instruments", "nodes").length).to eq(3)
      expect(response.dig("data", "instruments", "nodes", 0, "id")).to eq(instruments.first.identifier)
    end
  end

  # describe "query datasets by person", elasticsearch: true do
  #   let!(:instruments) { create_list(:doi, 3, types: { "resourceTypeGeneral" => "Other", "resourceType" => "Instrument" }, aasm_state: "findable") }
  #   let!(:instruments) { create(:doi, types: { "resourceTypeGeneral" => "Other", "resourceType" => "Instrument" }, aasm_state: "findable", creators:
  #     [{
  #       "familyName" => "Garza",
  #       "givenName" => "Kristian",
  #       "name" => "Garza, Kristian",
  #       "nameIdentifiers" => [{"nameIdentifier"=>"https://orcid.org/0000-0003-3484-6875", "nameIdentifierScheme"=>"ORCID", "schemeUri"=>"https://orcid.org"}],
  #       "nameType" => "Personal",
  #     }])
  #   }
  #   before do
  #     Doi.import
  #     sleep 2
  #   end

  #   let(:query) do
  #     %(query {
  #       instruments(userId: "https://orcid.org/0000-0003-1419-2405") {
  #         totalCount
  #         years {
  #           id
  #           count
  #         }
  #         nodes {
  #           id
  #         }
  #       }
  #     })
  #   end

  #   it "returns instruments" do
  #     response = LupoSchema.execute(query).as_json

  #     expect(response.dig("data", "instruments", "totalCount")).to eq(3)
  #     expect(response.dig("data", "instruments", "years")).to eq([{"count"=>3, "id"=>"2011"}])
  #     expect(response.dig("data", "instruments", "nodes").length).to eq(3)
  #     expect(response.dig("data", "instruments", "nodes", 0, "id")).to eq(instruments.first.identifier)
  #   end
  # end
end
