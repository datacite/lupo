class ApiKeySerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :api_keys
  set_id :id

  attributes :name, :key_prefix, :created, :updated, :last_used_at, :revoked_at

  # Only include the plaintext key on creation
  attribute :key, if: Proc.new { |object, params| params && params[:include_plain_key] } do |object|
    object.key
  end

  attribute :created do |object|
    object.created_at&.iso8601
  end

  attribute :updated do |object|
    object.updated_at&.iso8601
  end

  belongs_to :client, record_type: :clients
end
