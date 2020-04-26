# frozen_string_literal: true

class Types::RelatedIdentifierType < Types::BaseObject
  description "Information about related identifiers"

  field :related_identifier, String, null: true, hash_key: "relatedIdentifier", description: "Related identifier"
  field :related_identifier_type, String, null: true, hash_key: "relatedIdentifierType", description: "Related identifier type"
  field :relation_type, String, null: true, hash_key: "relationType", description: "Relation type"
  field :related_metadata_scheme, String, null: true, hash_key: "relatedMetadataScheme", description: "Related metadata scheme"
  field :scheme_uri, String, null: true, hash_key: "schemeUri", description: "Scheme URI"
  field :scheme_type, String, null: true, hash_key: "schemeType", description: "Scheme type"
  field :resource_type_general, String, null: true, hash_key: "resourceTypeGeneral", description: "Resource type general"
end
