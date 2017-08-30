class MemberSerializer < ActiveModel::Serializer
  cache key: 'member'
  attributes :name, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated
  has_many :data_centers
  has_many :prefixes

  def id
    object.uid.downcase
  end

  def country
    object.country_code
  end

  def email
    object.contact_email
  end
end
