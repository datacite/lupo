class StatusSerializer < ActiveModel::Serializer
  cache key: 'status'

  attributes :state, :jobs
end
