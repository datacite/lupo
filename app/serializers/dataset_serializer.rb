class DatasetSerializer < ActiveModel::Serializer
  # include helper module for extracting identifier
  include Identifiable

  # include metadata helper methods
  include Metadatable

  attributes   :doi, :version, :datacentre, :is_active, :created, :deposited, :updated
  attribute :datacentre_id
  #  :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_metadata_status, :minted
  # has_one :datacentre, class_name: "Datacentre", foreign_key: :datacentre
  belongs_to :datacentre, serializer: DatacentreSerializer

  def id
    doi_as_url(object.doi)
    # object.doi
  end


  def deposited
    object.minted
  end

  def datacentre
    object.datacentre[:symbol]
  end

  def datacentre_id
    object.datacentre[:symbol]
  end

end
