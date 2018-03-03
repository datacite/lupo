class DoiSerializer < ActiveModel::Serializer
  include Bolognese::Utils
  include Bolognese::DoiUtils

  attributes :doi, :identifier, :url, :author, :title, :container_title, :description, :resource_type_subtype, :landing_page, :license, :version, :related_identifier, :schema_version, :state, :is_active, :reason, :xml, :published, :registered, :updated

  belongs_to :client, serializer: ClientSerializer
  belongs_to :provider, serializer: ProviderSerializer
  belongs_to :resource_type, serializer: ResourceTypeSerializer
  has_many :media, serializer: MediaSerializer

  def id
    object.doi.downcase
  end

  def doi
    object.doi.downcase
  end

  def title
    t = parse_attributes(object.title, content: "text", first: true)
    t.truncate(255) if t.is_a?(String)
  end

  def resource_type_subtype
    object.additional_type
  end

  def container_title
    object.container_title || object.publisher
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end

  def state
    object.aasm_state
  end

  def updated
    object.updated_at
  end

  def published
    object.date_published
  end

  def registered
    object.date_registered
  end

  def landing_page
    { status: object.last_landing_page_status,
      content_type: object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check }
  end

  def license
    Array.wrap(object.license).map { |l| l["id"] }.compact.unwrap
  end
end
