# frozen_string_literal: true

class RepositoryPrefixSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower
  set_type "repository-prefixes"
  set_id :uid

  attributes :created_at, :updated_at

  belongs_to :repository,
             object_method_name: :client, id_method_name: :client_id
  belongs_to :provider
  belongs_to :provider_prefix
  belongs_to :prefix
end
