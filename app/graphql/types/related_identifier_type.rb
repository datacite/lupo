# frozen_string_literal: true

class RelatedIdentifierType < BaseObject
  description "Information about related identifiers"

  field :related_identifier,
        String,
        null: false,
        description: "Related identifier"

  def related_identifier
    object["relatedIdentifier"]
  end

  field :related_identifier_type,
        String,
        null: false,
        description: "Related identifier type"

  def related_identifier_type
    object["relatedIdentifierType"]
  end

  field :relation_type,
        String,
        null: false, description: "Relation type"

  def relation_type
    object["relationType"]
  end

  field :related_metadata_scheme,
        String,
        null: true,
        description: "Related metadata scheme"

  def related_metadata_scheme
    object["relatedMetadataScheme"]
  end

  field :scheme_uri,
        String,
        null: true, description: "Scheme URI"

  def scheme_uri
    object["schemeUri"]
  end

  field :scheme_type,
        String,
        null: true, description: "Scheme type"

  def scheme_type
    object["schemeType"]
  end

  field :resource_type_general,
        String,
        null: true,
        description: "Resource type general"

  def resource_type_general
    object["resourceTypeGeneral"]
  end
end
