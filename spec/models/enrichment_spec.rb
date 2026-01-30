# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enrichment, type: :model do
  def valid_enrichment_attrs(doi:)
    {
      doi: doi,
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

  describe "associations" do
    it { is_expected.to belong_to(:doi_record).class_name("Doi") }
    it { is_expected.to have_one(:client).through(:doi_record) }
  end

  describe "scopes" do
    before do
      allow_any_instance_of(described_class).to receive(:validate_json_schema)
    end

    def create_enrichment!(doi:, updated_at: nil)
      attrs = valid_enrichment_attrs(doi: doi)
      attrs = attrs.merge(updated_at: updated_at) if updated_at
      described_class.create!(attrs)
    end

    describe ".by_doi" do
      it "returns enrichments matching the doi" do
        doi_a = create(:doi)
        doi_b = create(:doi)

        e1 = create_enrichment!(doi: doi_a.doi)
        _e2 = create_enrichment!(doi: doi_b.doi)

        expect(described_class.by_doi(doi_a.doi)).to contain_exactly(e1)
      end
    end

    describe ".by_client" do
      it "returns enrichments for DOIs belonging to the given client symbol (Client model backed by datacentre table)" do
        client_a = create(:client, symbol: "DATACITE.TEST")
        client_b = create(:client, symbol: "OTHER.TEST")

        doi_a = create(:doi, client: client_a)
        doi_b = create(:doi, client: client_b)

        e1 = create_enrichment!(doi: doi_a.doi)
        _e2 = create_enrichment!(doi: doi_b.doi)

        expect(described_class.by_client("DATACITE.TEST")).to contain_exactly(e1)
      end
    end

    describe ".order_by_cursor" do
      it "orders by updated_at desc then id desc" do
        doi = create(:doi)
        t = Time.utc(2026, 1, 29, 10, 0, 0)

        a = create_enrichment!(doi: doi.doi, updated_at: t)
        b = create_enrichment!(doi: doi.doi, updated_at: t)
        c = create_enrichment!(doi: doi.doi, updated_at: t + 1.second)

        ordered = described_class.where(id: [a.id, b.id, c.id]).order_by_cursor.to_a

        expect(ordered.first).to eq(c)
        expect(ordered[1].updated_at).to eq(t)
        expect(ordered[2].updated_at).to eq(t)
        expect(ordered[1].id).to be > ordered[2].id
      end
    end

    describe ".by_cursor" do
      it "filters to records before the cursor (updated_at desc, id desc tie-break)" do
        doi = create(:doi)
        t = Time.utc(2026, 1, 29, 10, 0, 0)

        older = create_enrichment!(doi: doi.doi, updated_at: t - 10.seconds)
        newer = create_enrichment!(doi: doi.doi, updated_at: t + 10.seconds)

        same_time_1 = create_enrichment!(doi: doi.doi, updated_at: t)
        same_time_2 = create_enrichment!(doi: doi.doi, updated_at: t)

        small, big = [same_time_1, same_time_2].sort_by(&:id)

        results = described_class.by_cursor(t, big.id)

        expect(results).to include(older, small)
        expect(results).not_to include(newer, big)
      end
    end
  end

  describe "json schema validation" do
    let(:valid_attributes) { valid_enrichment_attrs(doi: "10.1234/example") }

    context "happy paths (action-dependent requirements)" do
      it "is valid for action=update with original_value and enriched_value" do
        attrs = valid_attributes.merge(action: "update")
        enrichment = described_class.new(attrs)
        expect(enrichment).to be_valid
      end

      it "is valid for action=updateChild with original_value and enriched_value" do
        attrs = valid_attributes.merge(action: "updateChild")
        enrichment = described_class.new(attrs)
        expect(enrichment).to be_valid
      end

      it "is valid for action=insert when enriched_value is present (original_value may be omitted)" do
        attrs = valid_attributes.deep_dup
        attrs[:action] = "insert"
        attrs.delete(:original_value)

        enrichment = described_class.new(attrs)
        expect(enrichment).to be_valid
      end

      it "is valid for action=deleteChild when original_value is present (enriched_value may be omitted)" do
        attrs = valid_attributes.deep_dup
        attrs[:action] = "deleteChild"
        attrs.delete(:enriched_value)

        enrichment = described_class.new(attrs)
        expect(enrichment).to be_valid
      end
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
      it "fails when a required top-level attribute is missing (field)" do
        enrichment = described_class.new(valid_attributes.except(:field))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when a required top-level attribute is missing (doi)" do
        enrichment = described_class.new(valid_attributes.except(:doi))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when contributors is empty (minItems 1)" do
        enrichment = described_class.new(valid_attributes.merge(contributors: []))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when resources is empty (minItems 1)" do
        enrichment = described_class.new(valid_attributes.merge(resources: []))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when contributors contains an unexpected extra property (additionalProperties false)" do
        bad = valid_attributes.deep_dup
        bad[:contributors][0][:unexpected] = "nope"

        enrichment = described_class.new(bad)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when resources contains an unexpected extra property (additionalProperties false)" do
        bad = valid_attributes.deep_dup
        bad[:resources][0][:unexpected] = "nope"

        enrichment = described_class.new(bad)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when contributor is missing required keys (name and contributorType)" do
        bad = valid_attributes.deep_dup
        bad[:contributors] = [{ name: "Only name" }] # missing contributorType

        enrichment = described_class.new(bad)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when resource is missing required keys (relatedIdentifier, relationType, relatedIdentifierType)" do
        bad = valid_attributes.deep_dup
        bad[:resources] = [{ relatedIdentifier: "10.1234/x" }] # missing relationType + relatedIdentifierType

        enrichment = described_class.new(bad)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when action=updateChild but original_value is missing (schema requires originalValue)" do
        enrichment = described_class.new(valid_attributes.except(:original_value))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when action=updateChild but enriched_value is missing (schema requires enrichedValue)" do
        enrichment = described_class.new(valid_attributes.except(:enriched_value))

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when action=insert but enriched_value is missing (schema requires enrichedValue)" do
        attrs = valid_attributes.deep_dup
        attrs[:action] = "insert"
        attrs.delete(:enriched_value)

        enrichment = described_class.new(attrs)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "fails when action=deleteChild but original_value is missing (schema requires originalValue)" do
        attrs = valid_attributes.deep_dup
        attrs[:action] = "deleteChild"
        attrs.delete(:original_value)

        enrichment = described_class.new(attrs)

        expect(enrichment).not_to be_valid
        expect(enrichment.errors[:base].join(" ")).to include("Validation failed")
      end

      it "adds a base error that starts with 'Validation failed:'" do
        enrichment = described_class.new(valid_attributes.except(:field))
        enrichment.validate

        expect(enrichment.errors[:base].first).to match(/\AValidation failed:/)
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

        expected = {
          "doi" => valid_attributes[:doi],
          "contributors" => valid_attributes[:contributors],
          "resources" => valid_attributes[:resources],
          "field" => valid_attributes[:field],
          "action" => valid_attributes[:action],
          "originalValue" => valid_attributes[:original_value],
          "enrichedValue" => valid_attributes[:enriched_value]
        }.deep_stringify_keys

        expect(hash).to include(expected)
      end

      it "compacts nil values (omits keys when underlying attributes are nil)" do
        enrichment = described_class.new(valid_attributes.merge(enriched_value: nil))
        hash = enrichment.send(:to_enrichment_hash)

        expect(hash).not_to have_key("enrichedValue")
      end
    end
  end
end
