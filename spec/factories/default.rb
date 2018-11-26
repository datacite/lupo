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
    xml { '<?xml version="1.0" encoding="UTF-8"?>
      <resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-4" xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd">
        <identifier identifierType="DOI">10.14454/4K3M-NYVG</identifier>
        <creators>
          <creator>
            <creatorName>Fenner, Martin</creatorName>
            <givenName>Martin</givenName>
            <familyName>Fenner</familyName>
            <nameIdentifier schemeURI="http://orcid.org/" nameIdentifierScheme="ORCID">0000-0003-1419-2405</nameIdentifier>
          </creator>
        </creators>
        <titles>
          <title>Eating your own Dog Food</title>
        </titles>
        <publisher>DataCite</publisher>
        <publicationYear>2016</publicationYear>
        <resourceType resourceTypeGeneral="Text">BlogPosting</resourceType>
        <alternateIdentifiers>
          <alternateIdentifier alternateIdentifierType="Local accession number">MS-49-3632-5083</alternateIdentifier>
        </alternateIdentifiers>
        <subjects>
          <subject>datacite</subject>
          <subject>doi</subject>
          <subject>metadata</subject>
        </subjects>
        <dates>
          <date dateType="Created">2016-12-20</date>
          <date dateType="Issued">2016-12-20</date>
          <date dateType="Updated">2016-12-20</date>
        </dates>
        <relatedIdentifiers>
          <relatedIdentifier relatedIdentifierType="DOI" relationType="References">10.5438/0012</relatedIdentifier>
          <relatedIdentifier relatedIdentifierType="DOI" relationType="References">10.5438/55E5-T5C0</relatedIdentifier>
          <relatedIdentifier relatedIdentifierType="DOI" relationType="IsPartOf">10.5438/0000-00SS</relatedIdentifier>
        </relatedIdentifiers>
        <version>1.0</version>
        <descriptions>
          <description descriptionType="Abstract">Eating your own dog food is a slang term to describe that an organization should itself use the products and services it provides. For DataCite this means that we should use DOIs with appropriate metadata and strategies for long-term preservation for...</description>
        </descriptions>
      </resource>' }
    aasm_state { "draft" }
    source { "test" }
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
    is_active { true }

    initialize_with { Provider.where(symbol: symbol).first_or_initialize }
  end

  factory :provider_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider, factory: :provider, strategy: :create
  end
end
