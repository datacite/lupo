class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :created, :doi, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_landing_page_status_check, :updated, :version, :datacentre, :minted
  has_one :datacentre, class_name: "Datacentre", foreign_key: :datacentre


  def deposited
    @model.minted
  end

end
