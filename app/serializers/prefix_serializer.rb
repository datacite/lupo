class PrefixSerializer < ActiveModel::Serializer
  cache key: 'prefix'
  type 'prefixes'

  attributes :registration_agency, :created, :updated

  has_many :datacenters
  has_many :members

  def id
    object.uid
  end

  def updated
    object.updated_at
  end
end
