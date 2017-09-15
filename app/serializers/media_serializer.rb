class MediaSerializer < ActiveModel::Serializer
  cache key: 'media'
  
  attributes :id, :created, :updated, :dataset_id, :version, :url, :media_type
  belongs_to :dataset, serializer: DatasetSerializer

  def dataset_id
    object.dataset.uid
  end
end
