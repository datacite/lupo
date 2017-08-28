class PrefixSerializer < ActiveModel::Serializer
  attributes :prefix, :version, :created, :updated
  belongs_to :datacenter, serializer: DatacenterSerializer
  belongs_to :member, serializer: MemberSerializer

  def id
    object.uid.downcase
  end
end
