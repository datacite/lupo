class PrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :prefixes
  set_id :prefix
  cache_options enabled: true, cache_length: 24.hours

  attributes :registration_agency, :created, :updated

  has_many :clients, record_type: :clients
  has_many :providers, record_type: :providers
end
