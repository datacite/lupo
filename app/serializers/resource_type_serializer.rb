class ResourceTypeSerializer < ActiveModel::Serializer
  cache key: 'resource_type'
  attributes :title, :updated

  def updated
    object.updated_at
  end
end
