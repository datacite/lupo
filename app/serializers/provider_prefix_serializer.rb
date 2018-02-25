class ProviderPrefixSerializer < ActiveModel::Serializer
  attributes :created, :updated

  belongs_to :provider
  belongs_to :prefix
  has_many :clients

  def id
    object.uid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
