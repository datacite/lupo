class DatasetSerializer < ActiveModel::Serializer
  cache key: 'dataset'
  # include helper module for extracting identifier
  # type "works"
  include Identifiable
  # include metadata helper methods
  include Metadatable

  attributes   :doi, :version, :datacenter_id, :is_active, :created, :minted, :updated
  belongs_to :datacenter, serializer: DatacenterSerializer
  has_many :media
  has_many :metadata

  def id
    object.uid.downcase
  end

end
