# frozen_string_literal: true

require "rails_helper"

describe InstrumentType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type("ID!") }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "query instruments", elasticsearch: true do
    let!(:instruments) do
      create_list(
        :doi,
        3,
        types: {
          "resourceTypeGeneral" => "Other", "resourceType" => "Instrument"
        },
        aasm_state: "findable",
      )
    end

    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 3 }).results.to_a
    end

    let(:query) do
      "query {
        instruments {
          totalCount
          nodes {
            id
          }
        }
      }"
    end

    it "returns all instruments" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "instruments", "totalCount")).to eq(3)
      expect(response.dig("data", "instruments", "nodes").length).to eq(3)
      expect(response.dig("data", "instruments", "nodes", 0, "id")).to eq(
        @dois.first.identifier,
      )
    end
  end
end
