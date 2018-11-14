class ResourceTypeSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type "resource-types"
  cache_options enabled: true, cache_length: 24.hours

  attributes :title, :updated
end
