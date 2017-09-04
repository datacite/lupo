class ProviderSerializer < ActiveModel::Serializer
  cache key: 'provider'

  attributes :name, :description, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated
  has_many :clients
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
