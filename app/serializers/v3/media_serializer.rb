# frozen_string_literal: true
module V3
class MediaSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :media
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :version, :url, :media_type, :created, :updated

  belongs_to :datacite_doi, record_type: :datacite_dois
end
end
