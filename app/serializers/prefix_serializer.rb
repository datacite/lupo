class PrefixSerializer < ActiveModel::Serializer
  attributes :prefix, :version, :created
  belongs_to :datacenter, serializer: DatacenterSerializer
  belongs_to :member, serializer: MemberSerializer

  def id
    object.prefix
  end

  def created
    object.created.iso8601
  end
end
