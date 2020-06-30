require "faker"

FactoryBot.define do
  factory :user do
    sequence(:name) { |_n| "Josiah Carberry{n}" }
    provider { "globus" }
    role_id { "user" }
    sequence(:uid) { |n| "0000-0002-1825-000#{n}" }

    factory :admin_user do
      role_id { "staff_admin" }
      uid { "0000-0002-1825-0003" }
    end

    factory :staff_user do
      role_id { "staff_user" }
      uid { "0000-0002-1825-0004" }
    end

    factory :regular_user do
      role_id { "user" }
      uid { "0000-0002-1825-0001" }
    end

    factory :valid_user do
      uid { "0000-0001-6528-2027" }
      orcid_token { ENV["ACCESS_TOKEN"] }
    end

    factory :invalid_user do
      uid { "0000-0001-6528-2027" }
      orcid_token { nil }
    end

    initialize_with { User.new(User.generate_alb_token(uid: uid, role_id: role_id), type: "oidc") }
  end

  factory :client do
    provider

    system_email { "josiah@example.org" }
    service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    globus_uuid { "bc7d0274-3472-4a79-b631-e4c7baccc667" }
    sequence(:symbol) { |n| provider.symbol + ".TEST#{n}" }
    name { "My data center" }
    role_name { "ROLE_DATACENTRE" }
    password_input { "12345" }
    is_active { true }

    initialize_with { Client.where(symbol: symbol).first_or_initialize }
  end

  factory :client_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider_prefix, factory: :provider_prefix, strategy: :create
    association :client, factory: :client, strategy: :create
  end

  factory :doi do
    client

    doi { ("10.14454/" + Faker::Internet.password(8)).downcase }
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
      [
        {
          "title": "Data from: A new malaria agent in African hominids.",
        },
      ]
    end
    descriptions do
      [
        {
          "description": "Data from: A new malaria agent in African hominids.",
        },
      ]
    end
    publisher { "Dryad Digital Repository" }
    subjects do
      [
        {
          "subject": "Phylogeny",
        },
        {
          "subject": "Malaria",
        },
        {
          "subject": "Parasites",
        },
        {
          "subject": "Taxonomy",
        },
        {
          "subject": "Mitochondrial genome",
        },
        {
          "subject": "Africa",
        },
        {
          "subject": "Plasmodium",
        },
      ]
    end
    dates do
      [
        {
          "date": "2011",
          "dateType": "Issued",
        },
      ]
    end
    publication_year { 2011 }
    identifiers do
      [
        {
          "identifierType": "citation",
          "identifier": "Ollomo B, Durand P, Prugnolle F, Douzery EJP, Arnathau C, Nkoghe D, Leroy E, Renaud F (2009) A new malaria agent in African hominids. PLoS Pathogens 5(5): e1000446.",
        },
      ]
    end
    version { "1" }
    rights_list {[
      {
        "rightsUri": "https://creativecommons.org/publicdomain/zero/1.0/legalcode"
      }
    ]}
    related_identifiers {[
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
    sequence(:uid) { |n| "10.508#{n}" }
  end

  factory :provider do
    system_email { "josiah@example.org" }
    sequence(:symbol, 'A') { |n| "TEST#{n}" }
    role_name { "ROLE_ALLOCATOR" }
    globus_uuid { "53d8d984-450d-4b1d-970b-67faff28db1c" }
    name { "My provider" }
    display_name { "My provider" }
    website { Faker::Internet.url }
    country_code { "DE" }
    password_input { "12345" }
    twitter_handle { "@egaTwitterlac" }
    ror_id { "https://ror.org/05njkjr15" }
    billing_information do
      {
        "city": "barcelona",
        "state": "cataluyna",
        "department": "sales",
        "country": "CN",
        "organization": "testing org",
        "address": Faker::Address.street_address,
        "postCode": "10777",
      }
    end
    technical_contact do
      {
        "email": "kristian@example.com",
        "given_name": "Kristian",
        "family_name": "Garza",
      }
    end
    secondary_technical_contact do
      {
        "email": "kristian@example.com",
        "given_name": "Kristian",
        "family_name": "Garza",
      }
    end
    billing_contact do
      {
        "email": "trisha@example.com",
        "given_name": "Trisha",
        "family_name": "Cruse",
      }
    end
    secondary_billing_contact do
      {
        "email": "trisha@example.com",
        "given_name": "Trisha",
        "family_name": "Cruse",
      }
    end
    service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    secondary_service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    voting_contact do
      {
        "email": "robin@example.com",
        "given_name": "Robin",
        "family_name": "Dasler",
      }
    end
    is_active { true }

    initialize_with { Provider.where(symbol: symbol).first_or_initialize }
  end

  factory :provider_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider, factory: :provider, strategy: :create
  end

  factory :activity do
    association :auditable, factory: :doi, strategy: :create
  end

  factory :event do
    uuid { SecureRandom.uuid }
    source_id { "citeulike" }
    source_token { "citeulike_123" }
    sequence(:subj_id) { |n| "http://www.citeulike.org/user/dbogartoit/#{n}" }
    obj_id { "http://doi.org/10.1371/journal.pmed.0030186" }
    subj do
      { "@id" => "http://www.citeulike.org/user/dbogartoit",
        "@type" => "CreativeWork",
        "uid" => "http://www.citeulike.org/user/dbogartoit",
        "author" => [{ "given" => "dbogartoit" }],
        "name" => "CiteULike bookmarks for user dbogartoit",
        "publisher" => "CiteULike",
        "datePublished" => "2006-06-13T16:14:19Z",
        "url" => "http://www.citeulike.org/user/dbogartoit" }
    end
    obj {}
    relation_type_id { "bookmarks" }
    updated_at { Time.zone.now }
    occurred_at { Time.zone.now }

    factory :event_for_datacite_related do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      sequence(:subj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      subj { { "date_published" => "2006-06-13T16:14:19Z", "registrant_id" => "datacite.datacite" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "references" }
    end

    factory :event_for_datacite_parts do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      sequence(:obj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5/#{n}" }
      relation_type_id { "has-part" }
    end

    factory :event_for_datacite_part_of do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      relation_type_id { "is-part-of" }
    end

    factory :event_for_datacite_versions do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      sequence(:obj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5/#{n}" }
      relation_type_id { "has-version" }
    end

    factory :event_for_datacite_version_of do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      relation_type_id { "is-version-of" }
    end

    factory :event_for_datacite_crossref do
      source_id { "datacite_crossref" }
      source_token { "datacite_crossref_123" }
      sequence(:subj_id) { |n| "https://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "https://doi.org/10.1371/journal.pbio.2001414" }
      relation_type_id { "is-referenced-by" }
    end

    factory :event_for_crossref do
      source_id { "crossref" }
      source_token { "crossref_123" }
      subj_id { "https://doi.org/10.1371/journal.pbio.2001414" }
      sequence(:obj_id) { |n| "https://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      relation_type_id { "references" }
    end

    factory :event_for_datacite_investigations do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { 25 }
      sequence(:subj_id) { |_n| "https://api.test.datacite.org/report/#{SecureRandom.uuid}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj { { "date_published" => "2007-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-investigations-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_requests do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { 10 }
      sequence(:subj_id) { |_n| "https://api.test.datacite.org/report/#{SecureRandom.uuid}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj { { "date_published" => "2007-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-requests-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_usage_empty do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { rand(1..100).to_int }
      sequence(:subj_id) { |_n| "https://api.test.datacite.org/report/#{SecureRandom.uuid}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj {}
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-investigations-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_usage do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { rand(1..100).to_int }
      sequence(:subj_id) { |_n| "https://api.test.datacite.org/report/#{SecureRandom.uuid}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj { { "date_published" => "2007-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-investigations-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_orcid_auto_update do
      source_id { "datacite-orcid-auto-update" }
      source_token { "5348967fhdjksr3wyui325" }
      sequence(:obj_id) { |n| "https://orcid.org/0000-0003-1419-211#{n}}" }
      sequence(:subj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      relation_type_id { "is-authored-by" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end
  end
end
