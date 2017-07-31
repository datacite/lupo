class DatasetSerializer < ActiveModel::Serializer
  # include helper module for extracting identifier
  include Identifiable

  # include metadata helper methods
  include Metadatable

  attributes   :doi, :version, :datacentre, :is_active, :created, :deposited, :updated
  attribute    :datacentre_id
  belongs_to :datacentre, serializer: DatacentreSerializer

  def id
    doi_as_url(object.doi)
  end


  def deposited
    object.minted
  end

  def datacentre
    object.datacentre[:symbol].downcase
  end

  def datacentre_id
    object.datacentre[:symbol].downcase
  end

  def updated
    object.updated.iso8601
  end

  def created
    object.created.iso8601
  end

end
