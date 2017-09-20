class DoiSerializer < ActiveModel::Serializer
  #cache key: 'doi'

  attributes :doi, :identifier, :url, :xml, :media, :author, :title, :container_title, :description, :resource_type_subtype, :license, :version, :results, :related_identifiers, :schema_version, :published, :registered, :updated

  belongs_to :client, serializer: ClientSerializer
  belongs_to :provider, serializer: ProviderSerializer
  belongs_to :resource_type, serializer: ResourceTypeSerializer

  def updated
    object.updated_at
  end
end
