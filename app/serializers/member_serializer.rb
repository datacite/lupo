class MemberSerializer < ActiveModel::Serializer
  cache key: 'member'

  attributes :name, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  # if @scope.current_user.is_admin?
  #   attributes :role_name, :doi_quota_allowed, :is_active
  # end
  has_many :datacenters
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
