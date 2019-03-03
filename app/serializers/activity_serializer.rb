class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid
  
  attributes :doi, :identifiers, :creators, :titles, :publisher, :container, :publication_year, :subjects, :contributors, :dates, :language, :types, :related_identifiers, :sizes, :formats, :version, :rights_list, :descriptions, :geo_locations, :funding_references, :url, :content_url, :metadata_version, :schema_version, :source, :state, :landing_page, :username, :created

  belongs_to :doi, record_type: :dois

  attribute :doi do |object|
    object.uid
  end

  attribute :state do |object|
    object.aasm_state
  end

  attribute :version do |object|
    object.version_info
  end
end