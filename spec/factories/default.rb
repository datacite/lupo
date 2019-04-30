require 'faker'

FactoryBot.define do
  factory :client do
    provider

    contact_email { "josiah@example.org" }
    contact_name { "Josiah Carberry" }
    sequence(:symbol) { |n| provider.symbol + ".TEST#{n}" }
    name { "My data center" }
    role_name { "ROLE_DATACENTRE" }
    password_input { "12345" }
    is_active { true }

    initialize_with { Client.where(symbol: symbol).first_or_initialize }
  end

  factory :client_prefix do
    prefix
    provider_prefix
    client
  end

  factory :doi do
    client

    doi { ("10.14454/" + Faker::Internet.password(8)).downcase }
    url { Faker::Internet.url }
    types { {
      "resourceTypeGeneral": "Dataset",
      "resourceType": "DataPackage",
      "schemaOrg": "Dataset",
      "citeproc": "dataset",
      "bibtex": "misc",
      "ris": "DATA"
    }}
    creators { [
      {
        "nameType": "Personal",
        "name": "Benjamin Ollomo",
        "givenName": "Benjamin",
        "familyName": "Ollomo"
      },
      {
        "nameType": "Personal",
        "name": "Patrick Durand",
        "givenName": "Patrick",
        "familyName": "Durand"
      },
      {
        "nameType": "Personal",
        "name": "Franck Prugnolle",
        "givenName": "Franck",
        "familyName": "Prugnolle"
      },
      {
        "nameType": "Personal",
        "name": "Emmanuel J. P. Douzery",
        "givenName": "Emmanuel J. P.",
        "familyName": "Douzery"
      },
      {
        "nameType": "Personal",
        "name": "Céline Arnathau",
        "givenName": "Céline",
        "familyName": "Arnathau"
      },
      {
        "nameType": "Personal",
        "name": "Dieudonné Nkoghe",
        "givenName": "Dieudonné",
        "familyName": "Nkoghe"
      },
      {
        "nameType": "Personal",
        "name": "Eric Leroy",
        "givenName": "Eric",
        "familyName": "Leroy"
      },
      {
        "nameType": "Personal",
        "name": "François Renaud",
        "givenName": "François",
        "familyName": "Renaud",
        "nameIdentifiers": [
          {
            "nameIdentifier": "https://orcid.org/0000-0003-1419-2405",
            "nameIdentifierScheme": "ORCID",
            "schemeUri": "https://orcid.org"
          }
        ]
      }
    ] }
    titles {[
        {
          "title": "Data from: A new malaria agent in African hominids."
        }] }
    descriptions {[
      {
        "description": "Data from: A new malaria agent in African hominids."
      }] }
    publisher {"Dryad Digital Repository" }
    subjects {[
        {
          "subject": "Phylogeny"
        },
        {
          "subject": "Malaria"
        },
        {
          "subject": "Parasites"
        },
        {
          "subject": "Taxonomy"
        },
        {
          "subject": "Mitochondrial genome"
        },
        {
          "subject": "Africa"
        },
        {
          "subject": "Plasmodium"
        }
    ]}
    dates { [
      {
        "date": "2011",
        "dateType": "Issued"
      }
    ]}
    publication_year { 2011 }
    identifiers { [
      {
        "identifierType": "citation",
        "identifier": "Ollomo B, Durand P, Prugnolle F, Douzery EJP, Arnathau C, Nkoghe D, Leroy E, Renaud F (2009) A new malaria agent in African hominids. PLoS Pathogens 5(5): e1000446."
      }
    ]}
    version { "1" }
    rights_list {[
      {
        "rightsUri": "http://creativecommons.org/publicdomain/zero/1.0"
      }
    ]}
    related_identifiers {[
      {
        "relatedIdentifier": "10.5061/dryad.8515/1",
        "relatedIdentifierType": "DOI",
        "relationType": "HasPart"
      },
      {
        "relatedIdentifier": "10.5061/dryad.8515/2",
        "relatedIdentifierType": "DOI",
        "relationType": "HasPart"
      },
      {
        "relatedIdentifier": "10.1371/journal.ppat.1000446",
        "relatedIdentifierType": "DOI",
        "relationType": "IsReferencedBy"
      },
      {
        "relatedIdentifier": "10.1371/journal.ppat.1000446",
        "relatedIdentifierType": "DOI",
        "relationType": "IsSupplementTo"
      },
      {
        "relatedIdentifier": "19478877",
        "relatedIdentifierType": "PMID",
        "relationType": "IsReferencedBy"
      },
      {
        "relatedIdentifier": "19478877",
        "relatedIdentifierType": "PMID",
        "relationType": "IsSupplementTo"
      }
    ]}
    schema_version { "http://datacite.org/schema/kernel-4" }
    source { "test" }
    regenerate { true }
    created { Faker::Time.backward(14, :evening) }
    minted { Faker::Time.backward(15, :evening) }
    updated { Faker::Time.backward(5, :evening) }

    initialize_with { Doi.where(doi: doi).first_or_initialize }
  end

  factory :metadata do
    doi
  end

  factory :media do
    doi

    url { Faker::Internet.url }
    media_type { "application/json" }
  end

  factory :prefix do
    sequence(:prefix) { |n| "10.508#{n}" }
  end

  factory :provider do
    contact_email { "josiah@example.org" }
    contact_name  { "Josiah Carberry" }
    sequence(:symbol) { |n| "TEST#{n}" }
    name { "My provider" }
    country_code { "DE" }
    password_input { "12345" }
    twitter_handle { "megaTwitterlace" }
    ror_id { "https://ror.org/05njkjr15" }
    billing_information {{
      "city": "barcelona",
      "state": "cataluyna",
      "address": Faker::Address.street_address,
      "postCode": "10777"
     }}
    is_active { true }

    initialize_with { Provider.where(symbol: symbol).first_or_initialize }
  end

  factory :provider_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider, factory: :provider, strategy: :create
  end
end
