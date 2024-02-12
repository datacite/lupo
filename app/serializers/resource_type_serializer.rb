# frozen_string_literal: true

class ResourceTypeSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :dash
  set_type "resource-types"
  # cache_options enabled: true, cache_length: 24.hours
  cache_options store: Rails.cache, namespace: 'jsonapi-serializer', expires_in: 24.hours

  attributes :title, :updated
end
