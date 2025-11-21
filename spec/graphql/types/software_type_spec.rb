# frozen_string_literal: true

require "rails_helper"

describe SoftwareType do
  describe "fields" do
    subject { described_class }

    it { is_expected.to have_field(:id).of_type(!types.ID) }
    it { is_expected.to have_field(:type).of_type("String!") }
  end

  describe "software as formatted citation", elasticsearch: true do
    let!(:software) do
      create(
        :doi,
        types: { "resourceTypeGeneral" => "Software" },
        doi: "10.14454/12345",
        aasm_state: "findable",
        version_info: "1.0.1",
      )
    end
    before do
      Doi.import
      sleep 2
      @dois = Doi.gql_query(nil, page: { cursor: [], size: 1 }).results.to_a
    end

    let(:query) do
      "query {
        software(id: \"https://doi.org/10.14454/12345\") {
          id
          formattedCitation(style: \"apa\")
        }
      }"
    end

    it "returns books" do
      response = LupoSchema.execute(query).as_json

      expect(response.dig("data", "software", "id")).to eq(
        "https://handle.stage.datacite.org/" + software.uid,
      )
      expect(response.dig("data", "software", "formattedCitation")).to eq(
        "Ollomo, B., Durand, P., Prugnolle, F., Douzery, E. J. P., Arnathau, C., Nkoghe, D., Leroy, E., &amp; Renaud, F. (2011). Data from: A new malaria agent in African hominids. In <i>Physics letters / B</i> (Version 1.0.1, Vol. 776, pp. 249–264) [Computer software]. Dryad Digital Repository. <a href='https://doi.org/10.14454/12345'>https://doi.org/10.14454/12345</a>",
      )
    end
  end
end
