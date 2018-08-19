class DoiSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :dois
  set_id :doi
  #cache_options enabled: true, cache_length: 24.hours

  attributes :doi, :identifier, :url, :prefix, :suffix

  attribute :author do |object|
    object.author_normalized
  end

  attribute :title do |object|
    object.title_normalized
  end

  attribute :description do |object|
    object.description_normalized
  end

  attributes :publisher, :resource_type_subtype, :metadata_version, :schema_version, :reason, :source, :created

  belongs_to :client
  belongs_to :provider
  belongs_to :resource_type
  has_many :media

  attribute :is_active do |object|
    object.is_active == "\u0001" ? true : false
  end

  attribute :landing_page do |object|
    { status: object.last_landing_page_status,
      "content-type" => object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check }
  end
end
