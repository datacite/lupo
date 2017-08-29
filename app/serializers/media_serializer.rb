class MediumSerializer < ActiveModel::Serializer
  attributes :id, :created, :updated, :dataset, :version, :url, :media_type
end
