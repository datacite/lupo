class ClientSerializer < ActiveModel::Serializer
  type 'clients'
  cache key: 'client'

  attributes :name, :provider_id, :year, :created, :updated
  attribute :domains, if: :can_read
  attribute :contact, if: :can_read
  attribute :email, if: :can_read

  has_many :prefixes
  belongs_to :provider

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

  def provider_id
    object.provider_symbol.downcase
  end

  # def domains
  #   object.domains.to_s.split(/\s*,\s*/).presence
  # end
end
