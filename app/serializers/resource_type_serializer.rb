# frozen_string_literal: true

class ResourceTypeSerializer
  include JSONAPI::Serializer

  set_key_transform :dash
  set_type "resource-types"
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 24.hours

  attributes :title, :updated
end
