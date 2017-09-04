class ClientSerializer < ActiveModel::Serializer
  type 'clients'
  cache key: 'client'

  attributes :name, :domains, :provider_id, :year, :created, :updated

  has_many :prefixes
  belongs_to :provider

  def id
    object.uid.downcase
  end

  def provider_id
    object.provider_symbol.downcase
  end

  def domains
    object.domains.to_s.split(/\s*,\s*/).presence
  end
end
