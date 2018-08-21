class DoiSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :dois
  set_id :uid
  #cache_options enabled: true, cache_length: 24.hours

  attributes :doi, :identifier, :url, :prefix, :suffix, :author, :title, :publisher, :resource_type_subtype, :description, :version, :metadata_version, :schema_version, :reason, :source, :state, :is_active, :landing_page, :published, :created, :registered, :updated, :xml

  belongs_to :client, record_type: :clients
  belongs_to :provider, record_type: :providers
  belongs_to :resource_type, record_type: :resource_types
  has_many :media

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :author do |object|
    object.author_normalized
  end

  attribute :title do |object|
    object.title_normalized
  end

  attribute :description do |object|
    object.description_normalized
  end

  attribute :state do |object|
    object.aasm_state
  end

  attribute :is_active do |object|
    object.is_active == "\u0001" ? true : false
  end

  attribute :version do |object|
    object.b_version
  end

  attribute :xml do |object|
    object.xml_encoded
  end

  attribute :landing_page do |object|
    { status: object.last_landing_page_status,
      "content-type" => object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check }
  end
end
