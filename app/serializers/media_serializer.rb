# frozen_string_literal: true

class MediaSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :media
  set_id :uid
  # cache_options enabled: true, cache_length: 24.hours
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 24.hours

  attributes :version, :url, :media_type, :created, :updated

  belongs_to :datacite_doi, record_type: :datacite_dois
end
