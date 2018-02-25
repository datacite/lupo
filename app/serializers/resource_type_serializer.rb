class ResourceTypeSerializer < ActiveModel::Serializer
  attributes :title, :updated

  def updated
    object.updated_at
  end
end
