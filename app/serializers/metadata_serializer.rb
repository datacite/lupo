class MetadataSerializer < ActiveModel::Serializer
  attributes :id, :created, :version, :metadata_version, :dataset_id, :is_converted_by_mds, :namespace, :xml
  belongs_to :dataset, serializer: DatasetSerializer

  def dataset_id
    object.dataset.uid
  end
end
