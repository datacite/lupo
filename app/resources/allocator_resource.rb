class AllocatorResource < JSONAPI::Resource
  attributes  :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :experiments
  has_many :datacentres
  has_many :prefixes

  def meta(options)
    {
      total: @model.datacentres.count
    }
   end

end
