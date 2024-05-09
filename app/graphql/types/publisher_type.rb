# frozen_string_literal: true

class PublisherType < BaseObject
  description "Publisher information"

  field :name,
        String,
        null: true,
        description: "The name of the publisher"
  field :publisher_identifier,
        String,
        null: true,
        hash_key: "publisherIdentifier",
        description: "Uniquely identifies the publisher, according to various schemes"
  field :publisher_identifier_scheme,
        String,
        null: true,
        hash_key: "publisherIdentifierScheme",
        description: "The name of the publisher identifier scheme"
  field :scheme_uri,
        String,
        null: true,
        hash_key: "schemeUri",
        description: "The URI of the publisher identifier scheme"
  field :lang, String, null: true, description: "Language"
end
