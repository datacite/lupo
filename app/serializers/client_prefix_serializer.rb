class ClientPrefixSerializer < ActiveModel::Serializer
  cache key: 'client_prefix'
  type 'client_prefixes'

  attributes :created, :updated

  belongs_to :client
  belongs_to :provider
  belongs_to :prefix

  def id
    object.uid
  end

  def updated
    object.updated_at
  end
end
