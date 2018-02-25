class MediaSerializer < ActiveModel::Serializer
  attributes :version, :url, :media_type, :created, :updated

  belongs_to :doi, serializer: DoiSerializer

  def id
    object.uid
  end
end
