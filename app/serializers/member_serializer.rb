class MemberSerializer < ActiveModel::Serializer
  attributes   :name, :member_type, :description, :member_type, :year, :image, :region, :country_code, :website, :logo, :doi_quota_allowed, :is_active, :created,  :updated
  has_many :datacenters
  has_many :prefixes
  [:name, :member_type, :description, :member_type, :year, :image, :region, :country_code, :website, :logo, :doi_quota_allowed, :is_active, :created,  :updated].map{|a| attribute(a) {object[:_source][a]}}



  def id
    object.symbol.downcase
  end

  def updated
    object.updated.iso8601
  end

  def created
    object.created.iso8601
  end
end
