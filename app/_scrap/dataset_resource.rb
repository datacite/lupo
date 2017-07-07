class DatasetResource < JSONAPI::Resource
  model_name 'Dataset'
  model_hint model: Dataset
  attributes  :created, :doi, :version, :is_active, :updated, :datacentre
  attribute :datacentre_id
  #  :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_metadata_status, :minted
  attribute :deposited
  has_one :datacentre, class_name: "Datacentre", foreign_key: :datacentre
  # key_type :string
  # I need the previous line to get the right ID

  def deposited
    @model.minted
  end

  #
  def datacentre()
    DatacentreResource.find_by_key(@model.datacentre.id)
  end

  def datacentre_id()
   @model.datacentre.id
  end


end
