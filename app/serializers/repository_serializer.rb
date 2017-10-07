class RepositorySerializer < ActiveModel::Serializer
  cache key: 'repository'
  attributes :name
end
