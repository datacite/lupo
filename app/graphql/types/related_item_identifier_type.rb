# frozen_string_literal: true

class RelatedItemIdentifierType < BaseObject
  description "Information about the related item identifier"

  field :related_item_identifier,
        String,
        null: false,
        description: "Related item identifier"

  def related_item_identifier
    object["relatedItemIdentifier"]
  end

  field :related_item_identifier_type,
        String,
        null: true,
        description: "Related item identifier type"

  def related_item_identifier_type
    object["relatedItemIdentifierType"]
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
end
