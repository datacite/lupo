class DataCenterSerializer < ActiveModel::Serializer
  attributes :title, :other_names, :prefixes, :member_id, :year, :created, :updated

  belongs_to :member, serializer: MemberSerializer

  def id
    object.symbol.downcase
  end

  def title
    object.name
  end

  def member_id
    object.provider_id
  end

  def other_names
    []
  end

  def prefixes
    []
  end

  def created
    object.created.iso8601
  end

  def updated
    object.updated.iso8601
  end
end
