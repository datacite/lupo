class PrefixResource < JSONAPI::Resource
  model_name 'Prefix'
  attributes  :created, :prefix, :version
  has_many :datacentres
  has_many :allocators

  def meta(options)
    {
      total: @model.allocators.count
    }
   end
end
