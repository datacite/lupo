require "rails_helper"

describe Types::InstrumentType do
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
end
