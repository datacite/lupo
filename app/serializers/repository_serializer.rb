class RepositorySerializer < ActiveModel::Serializer
  cache key: 'repository'
  attributes :name, :description, :repository_url, :created, :updated

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
