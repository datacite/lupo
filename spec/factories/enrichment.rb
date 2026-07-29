# frozen_string_literal: true

FactoryBot.define do
  factory :enrichment do
    association :doi_record, factory: :doi, strategy: :create

    field { "creators" }
    action { "updateChild" }
    source_id { "datacite.comet" }

    original_value do
      {
        "name" => "Arslan, M.",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "affiliation" => [],
      }
    end

    enriched_value do
      {
        "name" => "Arslan, M.",
        "nameType" => "Personal",
        "givenName" => "M.",
        "familyName" => "Arslan",
        "nameIdentifiers" => [],
        "affiliation" => [
          {
            "name" => "DataCite",
            "identifier" => "https://ror.org/04wxnsj81",
            "identifierScheme" => "ROR",
          },
        ],
      }
    end

    contributors do
      [{ "name" => "DataCite COMET", "contributorType" => "DataCurator" }]
    end

    resources do
      [{ "relatedIdentifier" => "https://ror.org/04wxnsj81", "relationType" => "IsDerivedFrom", "relatedIdentifierType" => "URL" }]
    end

    transient do
      doi { nil }
    end

    after(:build) do |enrichment, evaluator|
      enrichment.doi = evaluator.doi.presence || enrichment.doi_record.doi
    end
  end
end
