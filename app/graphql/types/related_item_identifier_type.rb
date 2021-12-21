# frozen_string_literal: true

class RelatedItemIdentifierType < BaseObject
  description "Information about the related item identifier"

  field :related_item_identifier,
        String,
        null: false,
        hash_key: "relatedItemIdentifier",
        description: "Related item identifier"
  field :related_item_identifier_type,
        String,
        null: true,
        hash_key: "relatedItemIdentifierType",
        description: "Related item identifier type"
  field :related_metadata_scheme,
        String,
        null: true,
        hash_key: "relatedMetadataScheme",
        description: "Related metadata scheme"
  field :scheme_uri,
        String,
        null: true, hash_key: "schemeUri", description: "Scheme URI"
  field :scheme_type,
        String,
        null: true, hash_key: "schemeType", description: "Scheme type"
end
