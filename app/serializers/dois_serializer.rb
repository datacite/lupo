class DoisSerializer < ActiveModel::Serializer
  cache key: 'dois'
  type "dois"

  attributes :doi, :identifier, :url, :xml, :media, :author, :title, :container_title, :description, :resource_type_id, :resource_type_subtype, :client_id, :provider_id, :license, :version, :results, :related_identifiers, :schema_version, :published, :registered, :updated

  belongs_to :client
  belongs_to :provider
  belongs_to :resource_type, serializer: ResourceTypeSerializer

  def updated
    object.updated_at
  end
end
