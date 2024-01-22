
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
          },
          {
            "relatedIdentifier": target_doi.doi,
            "relatedIdentifierType": "DOI",
            "relationType": "Cites",
            "resourceTypeGeneral": "Text",
          }
        ])
    end

    it "indexes related_dois" do
      expect(doi.related_dois.first["doi"]).to eq(target_doi.doi.downcase)
    end

    it "indexes related doi's client_id" do
      expect(doi.related_dois.first["client_id"]).to eq(target_doi.client_id)
    end

    it "indexes related doi's person_id" do
      expect(doi.related_dois.first["person_id"]).to eq(target_doi.person_id)
    end

    it "does not index related doi's claimed resource_type_id" do
      expect(doi.related_dois.first["resource_type_id"]).not_to eq("output_management_plan")
    end

    it "indexes related doi's true resource_type_id" do
      expect(doi.related_dois.first["resource_type_id"]).to eq("dataset")
    end

    it "indexes all relations to the related doi" do
      expect(doi.related_dois.first["relation_type"]).to eq(["has_part", "cites"])
    end
  end
end
