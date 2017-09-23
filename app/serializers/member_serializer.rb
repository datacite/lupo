class MemberSerializer < ActiveModel::Serializer
  cache key: 'member'
  attributes :title, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
