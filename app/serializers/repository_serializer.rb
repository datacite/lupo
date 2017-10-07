class RepositorySerializer < ActiveModel::Serializer
  cache key: 'repository'
  attributes :name, :additional_name, :description, :repository_url, :repository_contact, :subject, :repository_software, :created, :updated

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
