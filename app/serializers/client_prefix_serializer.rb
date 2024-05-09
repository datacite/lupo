# frozen_string_literal: true

class ClientPrefixSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type "client-prefixes"
  set_id :uid

  attributes :created_at, :updated_at

  belongs_to :client
  belongs_to :provider
  belongs_to :provider_prefix
  belongs_to :prefix
end
