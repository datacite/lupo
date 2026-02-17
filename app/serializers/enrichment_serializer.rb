# frozen_string_literal: true

class EnrichmentSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :enrichments
  set_id :id

  attributes :doi,
             :contributors,
             :resources,
             :field,
             :action,
             :original_value,
             :enriched_value

  # Ensure the DOI value is always serialized in lowercase
  attribute :doi do |object|
    object.doi&.downcase
  end

  # Map created_at to created
  attribute :created, &:created_at

  # Map updated_at to updated
  attribute :updated, &:updated_at
end
