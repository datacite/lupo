class DatacenterSerializer < ActiveModel::Serializer
  type 'data-centers'
  cache key: 'data-center'

  attributes :name, :domains, :member_id, :year, :created, :updated

  has_many :datasets
  has_many :prefixes
  belongs_to :member

  def id
    object.uid.downcase
  end

  def domains
    object.domains.to_s.split(/\s*,\s*/).presence
  end
end
