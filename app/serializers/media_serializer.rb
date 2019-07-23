class MediaSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :media
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :version, :url, :media_type, :created, :updated

  belongs_to :doi, record_type: :dois
end
