class DatasetResource < JSONAPI::Resource
  attributes  :created, :doi, :version, :is_active, :is_ref_quality, :last_landing_page_status, :last_landing_page_status_check, :last_metadata_status,  :updated, :datacentre, :minted
  has_one :datacentre, class_name: 'Datacentre', foreign_key: 'datacentre'

  # def meta(options)
  #   {
  #     total: @model.datasets.count
  #   }
  #  end
end
