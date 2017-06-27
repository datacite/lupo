class AllocatorSerializer < ActiveModel::Serializer
  attributes  :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :is_active, :name, :role_name, :symbol, :updated, :version, :experiments
  has_many :datacentres
  has_many :prefixes

  def id
    object.symbol
  end

end
