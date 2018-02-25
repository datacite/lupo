class MemberSerializer < ActiveModel::Serializer
  attributes :title, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  def id
    object.id.downcase
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
