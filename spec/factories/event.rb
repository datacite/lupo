# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    uuid { SecureRandom.uuid }
    source_id { "citeulike" }
    source_token { "citeulike_123" }
    sequence(:subj_id) { |n| "http://www.citeulike.org/user/dbogartoit/#{n}" }
    obj_id { "http://doi.org/10.1371/journal.pmed.0030186" }
    subj do
      {
        "@id" => "http://www.citeulike.org/user/dbogartoit",
        "@type" => "CreativeWork",
        "uid" => "http://www.citeulike.org/user/dbogartoit",
        "author" => [{ "given" => "dbogartoit" }],
        "name" => "CiteULike bookmarks for user dbogartoit",
        "publisher" => "CiteULike",
        "datePublished" => "2006-06-13T16:14:19Z",
        "url" => "http://www.citeulike.org/user/dbogartoit",
      }
    end
    obj { }
    relation_type_id { "bookmarks" }
    updated_at { Time.zone.now }
    occurred_at { Time.zone.now }

    factory :event_for_datacite_related do
      source_id { "datacite-related" }
      source_token { "datacite_related_123" }
      sequence(:subj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      subj do
        {
          "date_published" => "2006-06-13T16:14:19Z",
          "registrant_id" => "datacite.datacite",
        }
      end
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "references" }
    end

    factory :event_for_datacite_parts do
      source_id { "datacite-related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      sequence(:obj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5/#{n}" }
      relation_type_id { "has-part" }
    end

    factory :event_for_datacite_part_of do
      source_id { "datacite-related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      relation_type_id { "is-part-of" }
    end

    factory :event_for_datacite_versions do
      source_id { "datacite-related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      sequence(:obj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5/#{n}" }
      relation_type_id { "has-version" }
    end

    factory :event_for_datacite_version_of do
      source_id { "datacite-related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      relation_type_id { "is-version-of" }
    end

    factory :event_for_datacite_crossref do
      source_id { "datacite-crossref" }
      source_token { "datacite-crossref_123" }
      sequence(:subj_id) { |n| "https://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "https://doi.org/10.1371/journal.pbio.2001414" }
      relation_type_id { "is-referenced-by" }
    end

    factory :event_for_datacite_funder do
      source_id { "datacite_funder" }
      source_token { "datacite_funder_123" }
      sequence(:subj_id) { |n| "https://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj_id { "https://doi.org/10.13039/100000001" }
      relation_type_id { "is-funded-by" }
    end

    factory :event_for_crossref do
      source_id { "crossref" }
      source_token { "crossref_123" }
      subj_id { "https://doi.org/10.1371/journal.pbio.2001414" }
      sequence(:obj_id) { |n| "https://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      relation_type_id { "references" }
    end

    factory :event_for_crossref_import do
      source_id { "crossref_import" }
      source_token { "crossref_123" }
      subj_id { "https://doi.org/10.1371/journal.pbio.2001414" }
      obj_id { nil }
      relation_type_id { nil }
    end

    factory :event_for_datacite_investigations do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { 25 }
      sequence(:subj_id) do |_n|
        "https://api.test.datacite.org/report/#{SecureRandom.uuid}"
      end
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
      sequence(:subj_id) do |_n|
        "https://api.test.datacite.org/report/#{SecureRandom.uuid}"
      end
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
      sequence(:subj_id) do |_n|
        "https://api.test.datacite.org/report/#{SecureRandom.uuid}"
      end
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj { }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-investigations-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_usage do
      source_id { "datacite-usage" }
      source_token { "5348967fhdjksr3wyui325" }
      total { rand(1..100).to_int }
      sequence(:subj_id) do |_n|
        "https://api.test.datacite.org/report/#{SecureRandom.uuid}"
      end
      subj { { "datePublished" => "2006-06-13T16:14:19Z" } }
      obj { { "date_published" => "2007-06-13T16:14:19Z" } }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "unique-dataset-investigations-regular" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end

    factory :event_for_datacite_orcid_auto_update do
      source_id { "datacite-orcid-auto-update" }
      source_token { "5348967fhdjksr3wyui325" }
      sequence(:obj_id) { |n| "https://orcid.org/0000-0003-1419-211#{n}" }
      sequence(:subj_id) { |n| "http://doi.org/10.5061/DRYAD.47SD5e/#{n}" }
      relation_type_id { "is-authored-by" }
      occurred_at { "2015-06-13T16:14:19Z" }
    end
  end
end
