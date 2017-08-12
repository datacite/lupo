class DatasetSerializer < ActiveModel::Serializer
  # include helper module for extracting identifier
  include Identifiable

  # include metadata helper methods
  include Metadatable


  attributes   :doi, :url, :version, :datacentre, :is_active, :created, :deposited, :updated
  attribute    :datacenter_id
  belongs_to :datacenter, serializer: DatacenterSerializer

  # [:doi, :url, :datacenter_id, :version, :datacentre, :is_active, :created, :deposited, :updated].map{|a| attribute(a) {object[:_source][a]}}


  def id
    doi_as_url(object.doi)
  end


  def deposited
    object.minted
  end

  def datacenter
    object.datacenter[:symbol].downcase
  end

  def datacenter_id
    object.datacenter[:symbol].downcase
  end

  def updated
    object.updated.iso8601
  end

  def created
    object.created.iso8601
  end

end
