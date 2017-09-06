class ProviderSerializer < ActiveModel::Serializer
  cache key: 'provider'

  attributes :name, :description, :region, :country, :year, :logo_url, :website, :created, :updated
  attribute :contact, if: :can_read
  attribute :email, if: :can_read
  attribute :phone, if: :can_read

  has_many :clients
  has_many :prefixes

  def can_read
    # `scope` is current ability
    scope.can?(:read, object)
  end

  def id
    object.uid.downcase
  end

  def contact
    object.contact_name
  end

  def email
    object.contact_email
  end

  def country
    object.country_code
  end
end
