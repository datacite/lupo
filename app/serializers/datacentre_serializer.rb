class DatacentreSerializer < ActiveModel::Serializer
  attributes :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :role_name, :symbol, :updated, :version, :allocator, :experiments
  has_many :datasets
  has_many :prefixes, data: true, links: {self: true, related: true}
  belongs_to :allocator, serializer: AllocatorSerializer, foreign_key: :allocator

  #
  def allocator()
  #  AllocatorResource.find_by_key(@model.allocator.id)
   object.allocator.id
  end
  #
  def domains()
   object.domains.split(/\s*,\s*/)
  end

  def id
    object.symbol
  end

  def meta(options)
    {
      total: object.datacentres.count
    }
  end

end
