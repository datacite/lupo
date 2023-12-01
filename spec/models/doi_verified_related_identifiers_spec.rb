
# frozen_string_literal: true

require "rails_helper"

describe Doi, type: :model, vcr: true, elasticsearch: true do
  describe "related_doi" do
    let(:client) { create(:client) }
    let(:target_doi) do
      create(:doi,
        client: client,
        aasm_state: "findable",
        types: { "resourceTypeGeneral" => "Dataset" }
      )
    end
    let(:doi) do
      create(:doi,
        client: client,
        aasm_state: "findable",
        related_identifiers: [
          {
            "relatedIdentifier": target_doi.doi,
            "relatedIdentifierType": "DOI",
            "relationType": "HasPart",
            "resourceTypeGeneral": "OutputManagementPlan",
          }
        ])
    end

    it "indexes related_dois" do
      expect(doi.related_dois.first[:doi]).to eq(target_doi.doi)
    end

  end
end
