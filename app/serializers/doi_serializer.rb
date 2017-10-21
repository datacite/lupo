class DoiSerializer < ActiveModel::Serializer
  # cache key: 'doi', disabled as caching is done in the DoiSearch service
  type 'dois'

  attributes :doi, :identifier, :url, :author, :title, :container_title, :description, :resource_type_general, :resource_type, :license, :version, :related_identifier, :schema_version, :state, :xml, :published, :registered, :updated

  belongs_to :client, serializer: ClientSerializer
  belongs_to :provider, serializer: ProviderSerializer
  #belongs_to :resource_type, serializer: ResourceTypeSerializer
  has_many :media, serializer: MediaSerializer

  def id
    object.doi.downcase
  end

  def doi
    object.doi.downcase
  end

  def resource_type
    object.additional_type
  end

  def container_title
    object.container_title || object.publisher
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

  def license
    Array.wrap(object.license).map { |l| l["id"] }.compact.unwrap
  end
end
