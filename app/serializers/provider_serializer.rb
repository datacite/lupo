class ProviderSerializer < ActiveModel::Serializer
  cache key: 'provider'
  # type 'providers'

  attributes :name, :symbol, :year, :contact_name, :contact_email, :logo_url, :is_active, :password, :created, :updated

  has_many :clients
  has_many :prefixes, join_table: "datacentre_prefixes"

  def id
    object.symbol.downcase
  end

  def password
    object.password.present? ? "yes" : "not set"
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end
end
