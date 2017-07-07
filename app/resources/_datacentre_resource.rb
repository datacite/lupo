class DatacentreResource < JSONAPI::Resource
  model_name 'Datacentre'
  model_hint model: Datacentre
#   attributes  :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :password, :role_name, :symbol, :updated, :version, :experiments, :allocator
#   attribute :allocator_id
#   has_many :datasets
#   has_many :prefixes
#   has_one :allocator, class_name: 'Allocator', foreign_key: :allocator
#
#   def meta(options)
#     {
#       total: @model.datasets.count
#     }
#   end
#
#   # def allocator(context = nil)
#   #  super - [:allocator]
#   #  AllocatorResource.find_by_key(@model.allocator.id)
#   # end
#   #
#   # def allocator_id(context = {})
#   #  super - [:allocator]
#   #  @model.allocator.id
#   # end
#
# end
  attributes :comments, :contact_email, :contact_name, :created, :doi_quota_allowed, :doi_quota_used, :domains, :is_active, :name, :role_name, :symbol, :updated, :version, :allocator, :experiments, :datacentre_id
  attribute :domainsd
  has_many :datasets
  has_many :prefixes
  belongs_to :allocator #, serializer: AllocatorSerializer

  #
  def allocator()
  #  AllocatorResource.find_by_key(@model.allocator.id)
   @model.allocator.id
  end
  #
  def domainsd()
    if @model.domains.is_a? String
      @model.domains.split(/\s*,\s*/)
    end
  end

  def id
    @model.symbol
  end

  def datacentre_id
    @model.id
  end

  def meta(options)
    {
      total: @model.datacentres.count
    }
  end

end
