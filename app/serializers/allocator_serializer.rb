class AllocatorSerializer < ActiveModel::Serializer
  attributes   :name, :symbol, :member_type, :description, :member_type, :year, :image, :region, :country_code, :website, :logo, :doi_quota_allowed, :is_active, :created,  :updated
  has_many :datacentres
  has_many :prefixes

  def id
    object.symbol.downcase
  end

  # def title
  #   object.symbol.downcase
  # end

  def updated
    object.updated.change(:sec => 0)
  end

  def created
    object.created.change(:sec => 0)
  end

end
