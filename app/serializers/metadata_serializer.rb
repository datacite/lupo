class MetadataSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type "metadata"
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :version, :namespace, :xml, :created

  belongs_to :doi, record_type: :dois

  attribute :xml do |object|
    Base64.strict_encode64(object.xml)
  end

  attribute :version do |object|
    object.metadata_version
  end
end
