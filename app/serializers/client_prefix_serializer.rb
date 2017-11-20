class ClientPrefixSerializer < ActiveModel::Serializer
  cache key: 'client_prefix'
  type 'client_prefixes'

  attributes :created, :updated

  belongs_to :client
  belongs_to :provider
  belongs_to :provider_prefix
  belongs_to :prefix

  def id
    object.uid
  end

  def provider
    object.client.provider
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
