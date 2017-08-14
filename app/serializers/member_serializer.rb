class MemberSerializer < ActiveModel::Serializer
  type :members

  attributes :name, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  # if @scope.current_user.is_admin?
  #   attributes :role_name, :doi_quota_allowed, :is_active
  # end

  has_many :datacenters
  has_many :prefixes

  def id
    object.id
  end

  def name
    object.name
  end

  def description
    object.description
  end

  def member_type
    object.member_type
  end

  def year
    object.year
  end

  def region
    object.region
  end

  def country
    object.country
  end

  def email
    object.email
  end

  def website
    object.website
  end

  def phone
    object.phone
  end

  def logo_url
    object.logo_url
  end

  def role_name
    object.role_name
  end

  def updated
    object.updated
  end

  def created
    object.created
  end
end
