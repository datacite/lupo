# frozen_string_literal: true

FactoryBot.define do
  factory :enrichment do
    association :doi_record, factory: :doi, strategy: :create

    field { "creators" }
    action { "updateChild" }
    source_id { "10.0000/fake.test.doi.2026.001" }

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

    transient do
      doi { nil }
    end

    after(:build) do |enrichment, evaluator|
      enrichment.doi = evaluator.doi.presence || enrichment.doi_record.doi
    end
  end
end
