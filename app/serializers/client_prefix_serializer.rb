class ClientPrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type "client-prefixes"
  set_id :uid

  attributes :created_at, :updated_at

  belongs_to :client, record_type: :clients, if: Proc.new { |cp| cp.client_id }
  belongs_to :provider, record_type: :providers, if: Proc.new { |cp| cp.provider_id }
  belongs_to :provider_prefix, record_type: :provider_prefixes, if: Proc.new {|cp| cp.provider_prefix_id }
  belongs_to :prefix, record_type: :prefixes, if: Proc.new { |cp| cp.prefix_id }
end
