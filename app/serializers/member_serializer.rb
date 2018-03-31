class MemberSerializer < ActiveModel::Serializer
  type "members"

  attributes :title, :description, :member_type, :institution_type, :region, :country, :year, :logo_url, :email, :website, :phone, :joined, :created, :updated

  def id
    object.symbol.downcase
  end

  def title
    object.name
  end

  def country
    object.country_name
  end

  def region
    object.region_human_name
  end

  def email
    object.contact_email
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
