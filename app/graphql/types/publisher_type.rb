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
        description: "Uniquely identifies the publisher, according to various schemes"

  def publisher_identifier
    object["publisherIdentifier"]
  end

  field :publisher_identifier_scheme,
        String,
        null: true,
        description: "The name of the publisher identifier scheme"

  def publisher_identifier_scheme
    object["publisherIdentifierScheme"]
  end

  field :scheme_uri,
        String,
        null: true,
        description: "The URI of the publisher identifier scheme"

  def scheme_uri
    object["schemeUri"]
  end

  field :lang, String, null: true, description: "Language"
end
