# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enrichment, type: :model do
  describe "json schema validation" do
    let(:valid_attributes) do
      {
        doi: "10.1234/example",
        contributors: [
          {
            name: "COMET",
            nameType: "Organizational",
            contributorType: "ResearchGroup",
            affiliation: [],
            nameIdentifiers: []
          }
        ],
        resources: [
          {
            relatedIdentifier: "10.1234/example_dataset",
            relationType: "IsDerivedFrom",
            relatedIdentifierType: "DOI",
            resourceTypeGeneral: "Dataset"
          }
        ],
        field: "creators",
        action: "updateChild",
        original_value: {
          name: "Chadly, Duncan",
          nameType: "Personal",
          givenName: "Duncan",
          familyName: "Chadly",
          affiliation: [
            {
              name: "California Institute of Technology",
              affiliationIdentifier: "https://ror.org/05dxps055",
              affiliationIdentifierScheme: "ROR"
            }
          ],
          nameIdentifiers: [
            {
              nameIdentifier: "https://orcid.org/0000-0002-8417-1522",
              nameIdentifierScheme: "ORCID"
            }
          ]
        },
        enriched_value: {
          name: "Chadly, Duncan",
          nameType: "Personal",
          givenName: "Duncan",
          familyName: "Chadly",
          affiliation: [
            {
              name: "California Institute of Technology",
              affiliationIdentifier: "https://ror.org/05dxps055",
              affiliationIdentifierScheme: "ROR"
            }
          ],
          nameIdentifiers: [
            {
              nameIdentifier: "https://orcid.org/0000-0002-8417-1522",
              nameIdentifierScheme: "ORCID"
            }
          ]
        }
      }
    end

    context "when schema validation passes" do
      it "is valid" do
        enrichment = described_class.new(valid_attributes)
        expect(enrichment).to be_valid
      end

      it "does not add base errors" do
        enrichment = described_class.new(valid_attributes)
        enrichment.validate
        expect(enrichment.errors[:base]).to be_empty
      end
    end

    context "when schema validation fails" do
      it "adds a base error containing 'Validation failed'" do
        enrichment = described_class.new(valid_attributes.except(:field))
        expect(enrichment).not_to be_valid

        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "includes the raw schema error output (message or inspect) in the base error" do
        enrichment = described_class.new(valid_attributes.except(:field))
        enrichment.validate

        expect(enrichment.errors[:base].first).to match(/Validation failed:/)
      end
    end

    describe ".enrichment_schemer" do
      it "memoizes the schemer instance" do
        schemer1 = described_class.enrichment_schemer
        schemer2 = described_class.enrichment_schemer

        expect(schemer1).to be(schemer2)
      end
    end

    describe "#to_enrichment_hash" do
      it "includes the expected keys and uses camelCase for original/enriched values" do
        enrichment = described_class.new(valid_attributes)
        hash = enrichment.send(:to_enrichment_hash)

        expect(hash).to include(
          "doi" => valid_attributes[:doi],
          "contributors" => valid_attributes[:contributors],
          "resources" => valid_attributes[:resources],
          "field" => valid_attributes[:field],
          "action" => valid_attributes[:action],
          "originalValue" => valid_attributes[:original_value],
          "enrichedValue" => valid_attributes[:enriched_value]
        )
      end

      it "compacts nil values (omits keys when underlying attributes are nil)" do
        enrichment = described_class.new(valid_attributes.merge(enriched_value: nil))
        hash = enrichment.send(:to_enrichment_hash)

        expect(hash).not_to have_key("enrichedValue")
      end
    end
  end
end
