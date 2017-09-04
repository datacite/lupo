class DatasetSerializer < ActiveModel::Serializer
  cache key: 'dataset'
  # include helper module for extracting identifier
  # type "dois"
  include Identifiable
  # include metadata helper methods
  include Metadatable

  attributes   :doi, :url, :version, :client_id, :is_active, :created, :minted, :updated
  belongs_to :client, serializer: ClientSerializer
  has_many :media
  has_many :metadata

  def id
    object.uid.downcase
  end

end
