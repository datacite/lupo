class ProviderSerializer < ActiveModel::Serializer
  cache key: 'provider'

  attributes :name, :year, :contact, :email, :logo_url, :is_active, :created, :updated

  has_many :clients
  has_many :prefixes, join_table: "datacentre_prefixes"

  def id
    object.symbol.downcase
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end

  def contact
    object.contact_name
  end

  def email
    object.contact_email
  end
end
