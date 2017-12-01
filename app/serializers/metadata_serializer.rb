class MetadataSerializer < ActiveModel::Serializer
  attributes :id, :created, :version, :metadata_version, :dataset_id, :is_converted_by_mds, :namespace, :xml
  belongs_to :doi, serializer: DoiSerializer

  def dataset_id
    object.try(:dataset) && object.dataset.uid
  end

  def is_converted_by_mds
    object.try(:is_converted_by_mds)
  end

  def namespace
    object.try(:namespace)
  end
end
