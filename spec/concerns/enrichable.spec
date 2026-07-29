require "rails_helper"

describe Enrichable, vcr: true do
  let(:doi) { create(:doi, creators:
    [
      {
        "name": "Arslan, M.",
        "givenName": "M.",
        "familyName": "Arslan",
        "affiliation": []
      },
      {
        "name": "Asker, E.",
        "nameType": "Personal",
        "givenName": "E.",
        "familyName": "Asker",
        "affiliation": []
      }
    ]
  ) }

  describe "applies enrichment to DOI" do
    it "when action is updateChild and original_value matches exactly" do
      original_creators = doi.creators.deep_dup

      enrichment = build(:enrichment, doi: doi.doi)

      doi.regenerate = true
      doi.apply_enrichment(enrichment)

      expect(doi.valid?).to be true
      expect(doi.creators.first).to eq(enrichment.enriched_value)
      expect(doi.creators.second).to eq(original_creators.second)
    end

    it "when action is updateChild and original_value contains additional empty or nil values" do
      original_creators = doi.creators.deep_dup

      enrichment = build(
        :enrichment,
        doi: doi.doi,
        original_value: {
          "name": "Arslan, M.",
          "nameType": nil,
          "givenName": "M.",
          "familyName": "Arslan",
          "affiliation": [],
          "nameIdentifiers": []
        }
      )

      doi.regenerate = true
      doi.apply_enrichment(enrichment)

      expect(doi.valid?).to be true
      expect(doi.creators.first).to eq(enrichment.enriched_value)
      expect(doi.creators.second).to eq(original_creators.second)
    end
  end
end
