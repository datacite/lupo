class DoiSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :dois
  set_id :uid

  attributes :doi, :identifier, :url, :prefix, :suffix, :types, :creator, :titles, :publisher, :periodical, :publication_year, :subjects, :contributor, :dates, :language, :alternate_identifiers, :related_identifiers, :sizes, :formats, :version, :rights_list, :descriptions, :funding_references, :metadata_version, :schema_version, :reason, :source, :state, :is_active, :landing_page, :created, :registered, :updated, :cache_key

  belongs_to :client, record_type: :clients
  belongs_to :resource_type, record_type: :resource_types
  has_many :media

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :is_active do |object|
    object.is_active == "\u0001" ? true : false
  end

  attribute :version do |object|
    object.version_info
  end

  attribute :landing_page do |object|
    { status: object.last_landing_page_status,
      "content-type" => object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check,
      "result" => object.try(:last_landing_page_status_result) }
  end
end
