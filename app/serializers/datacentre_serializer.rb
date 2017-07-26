class DatacentreSerializer < ActiveModel::Serializer
  attributes  :name, :role_name, :symbol,  :member_id, :contact_email, :doi_quota_allowed, :doi_quota_used, :version, :is_active, :created, :updated, :domains
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
    if object.domains.is_a? String
      object.domains.split(/\s*,\s*/)
    end
  end

  def id
    object.symbol.downcase
  end

  def updated
    object.updated.change(:sec => 0)
  end

  def created
    object.created.change(:sec => 0)
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
