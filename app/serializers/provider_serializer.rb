class ProviderSerializer < ActiveModel::Serializer
  attributes :name, :symbol, :website, :contact_name, :contact_email, :phone, :description, :country, :logo_url, :institution_type, :is_active, :has_password, :joined, :created, :updated

  has_many :clients
  has_many :prefixes, join_table: "datacentre_prefixes"

  def id
    object.symbol.downcase
  end

  def has_password
    object.password.present?
  end

  def country
    object.country_code
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end
end
