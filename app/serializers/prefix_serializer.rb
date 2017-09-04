class PrefixSerializer < ActiveModel::Serializer
  cache key: 'prefix'
  type 'prefixes'

  attributes :registration_agency, :created, :updated

  has_many :clients
  has_many :providers

  def id
    object.prefix
  end

  def updated
    object.updated_at
  end
end
