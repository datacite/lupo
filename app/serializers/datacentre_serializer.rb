class DatacentreSerializer < ActiveModel::Serializer
  attributes  :name, :role_name, :member_id, :contact_email, :doi_quota_allowed, :doi_quota_used, :version, :is_active, :created, :updated, :domains
  has_many :datasets
  # has_many :prefixes
  belongs_to :allocator, serializer: AllocatorSerializer

  # url [:allocators, :prefixes]
  #
  def member_id
   object.allocator[:symbol]
  end
  #
  def domains
    object.domains.to_s.split(/\s*,\s*/).presence
  end

  def id
    object.symbol.downcase
  end

  def updated
    object.updated.iso8601
  end

  def created
    object.created.iso8601
  end

  def prefixes
    object.prefixes.map { |p| p.prefix }
  end

  def meta(options)
    {
      total: object.datacentres.count
    }
  end

end
