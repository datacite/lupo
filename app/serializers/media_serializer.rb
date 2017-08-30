class MediaSerializer < ActiveModel::Serializer
  attributes :id, :created, :updated, :dataset_id, :version, :url, :media_type
  belongs_to :dataset, serializer: DatasetSerializer

end
