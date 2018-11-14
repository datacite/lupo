class DoiSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :dois
  set_id :uid

  attributes :doi, :identifier, :creator, :titles, :publisher, :periodical, :publication_year, :subjects, :contributor, :dates, :language, :types, :alternate_identifiers, :related_identifiers, :sizes, :formats, :version, :rights_list, :descriptions, :geo_locations, :funding_references, :url, :content_url, :metadata_version, :schema_version, :source, :state, :reason, :landing_page, :created, :registered, :updated

  belongs_to :client, record_type: :clients
  belongs_to :resource_type, record_type: :resource_types
  has_many :media

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :version do |object|
    object.version_info
  end

  attribute :titles do |object|
    Array.wrap(object.titles).map { |i| i.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) }
  end

  attribute :subjects do |object|
    Array.wrap(object.subjects).map { |i| i.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) } }
  end

  attribute :alternate_identifiers do |object|
    Array.wrap(object.alternate_identifiers).map { |i| i.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) } }
  end

  attribute :related_identifiers do |object|
    Array.wrap(object.related_identifiers).map { |i| i.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) } }
  end

  attribute :types do |object|
    object.types.to_h.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) }
  end

  attribute :dates do |object|
    object.dates.to_h.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) }
  end

  attribute :descriptions do |object|
    Array.wrap(object.descriptions).map { |i| i.transform_keys { |key| key.to_s.camelize(uppercase_first_letter = false) } }
  end

  attribute :landing_page do |object|
    { status: object.last_landing_page_status,
      contentType: object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check,
      result: object.try(:last_landing_page_status_result) }
  end
end
