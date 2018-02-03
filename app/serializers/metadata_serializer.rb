class MetadataSerializer < ActiveModel::Serializer
  attributes :version, :namespace, :xml, :created
  belongs_to :doi, serializer: DoiSerializer

  def id
    object.uid
  end

  def xml
    Base64.strict_encode64(object.xml)
  end

  def version
    object.metadata_version
  end
end
