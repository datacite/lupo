class ProviderPrefixSerializer < ActiveModel::Serializer
  #cache key: 'provider_prefix'
  type 'provider_prefixes'

  attributes :created, :updated

  belongs_to :provider
  belongs_to :prefix

  def id
    object.uid
  end

  def updated
    object.updated_at
  end
end
