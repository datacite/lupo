class MetadataSerializer < ActiveModel::Serializer
  attributes :id, :created, :verion, :metadata_version, :dataset, :is_converted_by_mds, :namespace, :xml
end
