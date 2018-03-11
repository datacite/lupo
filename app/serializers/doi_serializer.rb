class DoiSerializer < ActiveModel::Serializer
  include Bolognese::Utils
  include Bolognese::DoiUtils

  attributes :doi, :identifier, :url, :creator, :title, :publisher, :publication_year, :resource_type_subtype, :description, :version, :metadata_version, :schema_version, :state, :is_active, :reason, :landing_page, :registered, :updated

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

  def creator
    Array.wrap(object.author)
  end

  def publication_year
    object.date_published[0..3].to_i if object.date_published.present?
  end

  def description
    parse_attributes(object.description, content: "text", first: true)
  end

  def resource_type_subtype
    object.additional_type
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

  def registered
    object.date_registered
  end

  def landing_page
    { url: object.last_landing_page,
      status: object.last_landing_page_status,
      content_type: object.last_landing_page_content_type,
      checked: object.last_landing_page_status_check }
  end

  # def license
  #   Array.wrap(object.license).map { |l| l["id"] }.compact.unwrap
  # end

  # def xml
  #   Base64.strict_encode64(object.xml) if object.xml.present?
  # end
end
