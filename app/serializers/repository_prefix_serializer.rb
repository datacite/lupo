class RepositoryPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type "repository-prefixes"
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :created, :updated

  belongs_to :repository, object_method_name: :client, id_method_name: :client_id, record_type: :repositories
  belongs_to :provider, record_type: :providers
  belongs_to :provider_prefix, record_type: :provider_prefixes
  belongs_to :prefix, record_type: :prefixes
end
