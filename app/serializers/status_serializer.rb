class StatusSerializer < ActiveModel::Serializer
  attributes :state, :jobs
end
