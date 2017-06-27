class PrefixSerializer < ActiveModel::Serializer
  attributes :created, :prefix, :version
  belongs_to :datacentre, serializer: DatacentreSerializer
  belongs_to :allocator, serializer: AllocatorSerializer

  def id
    object.prefix
  end

end
