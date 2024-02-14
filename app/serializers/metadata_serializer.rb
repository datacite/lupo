# frozen_string_literal: true

class MetadataSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type "metadata"
  set_id :uid
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 24.hours

  attributes :version, :namespace, :xml, :created

  belongs_to :datacite_doi, record_type: :datacite_dois

  attribute :xml do |object|
    Base64.strict_encode64(object.xml)
  end

  attribute :version, &:metadata_version
end
