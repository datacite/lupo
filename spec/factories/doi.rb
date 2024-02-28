# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :doi do
    client

    doi { ("10.14454/" + Faker::Internet.password(min_length: 8)).downcase }
    url { Faker::Internet.url }
    types do
      {
        "resourceTypeGeneral": "Dataset",
        "resourceType": "DataPackage",
        "schemaOrg": "Dataset",
        "citeproc": "dataset",
        "bibtex": "misc",
        "ris": "DATA",
      }
    end
    publisher_obj do
      {
        "name": "Dryad Digital Repository",
        "publisherIdentifier": "https://ror.org/00x6h5n95",
        "publisherIdentifierScheme": "ROR",
        "schemeUri": "https://ror.org/",
        "lang": "en",
      }
    end
    creators do
      [
        {
          "nameType": "Personal",
          "name": "Ollomo, Benjamin",
          "givenName": "Benjamin",
          "familyName": "Ollomo",
        },
        {
          "nameType": "Personal",
          "name": "Durand, Patrick",
          "givenName": "Patrick",
          "familyName": "Durand",
        },
        {
          "nameType": "Personal",
          "name": "Prugnolle, Franck",
          "givenName": "Franck",
          "familyName": "Prugnolle",
        },
        {
          "nameType": "Personal",
          "name": "Douzery, Emmanuel J. P.",
          "givenName": "Emmanuel J. P.",
          "familyName": "Douzery",
        },
        {
          "nameType": "Personal",
          "name": "Arnathau, Céline",
          "givenName": "Céline",
          "familyName": "Arnathau",
        },
        {
          "nameType": "Personal",
          "name": "Nkoghe, Dieudonné",
          "givenName": "Dieudonné",
          "familyName": "Nkoghe",
        },
        {
          "nameType": "Personal",
          "name": "Leroy, Eric",
          "givenName": "Eric",
          "familyName": "Leroy",
        },
        {
          "nameType": "Personal",
          "name": "Renaud, François",
          "givenName": "François",
          "familyName": "Renaud",
          "nameIdentifiers": [
            {
              "nameIdentifier": "https://orcid.org/0000-0003-1419-2405",
              "nameIdentifierScheme": "ORCID",
              "schemeUri": "https://orcid.org",
            },
          ],
          "affiliation": [
            {
              "name": "DataCite",
              "affiliationIdentifier": "https://ror.org/04wxnsj81",
              "affiliationIdentifierScheme": "ROR",
            },
          ],
        },
      ]
    end
    titles do
      [{ "title": "Data from: A new malaria agent in African hominids." }]
    end
    descriptions do
      [{ "description": "Data from: A new malaria agent in African hominids." }]
    end
    subjects do
      [
        { "subject": "Phylogeny" },
        { "subject": "Malaria" },
        { "subject": "Parasites" },
        { "subject": "Taxonomy" },
        { "subject": "Mitochondrial genome" },
        { "subject": "Africa" },
        { "subject": "Plasmodium" },
      ]
    end
    dates { [{ "date": "2011", "dateType": "Issued" }] }
    publication_year { 2_011 }
    identifiers do
      [{ "identifierType": "publisher ID", "identifier": "pk-1234" }]
    end
    version { "1" }
    rights_list do
      [
        {
          "rights" => "Creative Commons Zero v1.0 Universal",
          "rightsIdentifier" => "cc0-1.0",
          "rightsIdentifierScheme" => "SPDX",
          "rightsUri" =>
          "https://creativecommons.org/publicdomain/zero/1.0/legalcode",
            "schemeUri" => "https://spdx.org/licenses/",
        },
      ]
    end
    related_identifiers do
      [
        {
          "relatedIdentifier": "10.5061/dryad.8515/1",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
        },
        {
          "relatedIdentifier": "10.5061/dryad.8515/2",
          "relatedIdentifierType": "DOI",
          "relationType": "HasPart",
        },
        {
          "relatedIdentifier": "10.1371/journal.ppat.1000446",
          "relatedIdentifierType": "DOI",
          "relationType": "IsReferencedBy",
        },
        {
          "relatedIdentifier": "10.1371/journal.ppat.1000446",
          "relatedIdentifierType": "DOI",
          "relationType": "IsSupplementTo",
        },
        {
          "relatedIdentifier": "19478877",
          "relatedIdentifierType": "PMID",
          "relationType": "IsReferencedBy",
        },
        {
          "relatedIdentifier": "19478877",
          "relatedIdentifierType": "PMID",
          "relationType": "IsSupplementTo",
        },
      ]
    end
    related_items do
      [
        {
          "firstPage" => "249",
          "lastPage" => "264",
          "publicationYear" => "2018",
          "relatedItemIdentifier" => { "relatedItemIdentifier" => "10.1016/j.physletb.2017.11.044", "relatedItemIdentifierType" => "DOI" },
          "relatedItemType" => "Journal",
          "relationType" => "IsPublishedIn",
          "titles" => [{ "title" => "Physics letters / B" }],
          "volume" => "776"
        }
      ]
    end
    schema_version { "http://datacite.org/schema/kernel-4" }
    source { "test" }
    type { "DataciteDoi" }
    regenerate { true }
    created { Faker::Time.backward(days: 14, period: :evening) }
    minted { Faker::Time.backward(days: 15, period: :evening) }
    updated { Faker::Time.backward(days: 5, period: :evening) }

    initialize_with { DataciteDoi.where(doi: doi).first_or_initialize }
  end
end
