class DatacenterSerializer < ActiveModel::Serializer
  # type 'data-centers'

  attributes :name, :prefixes, :domains, :member_id, :year, :created, :updated

  def id
    object.uid.downcase
  end

  has_many :datasets
  has_many :prefixes
  belongs_to :member, serializer: MemberSerializer

  # def name
  #   object.name
  # end
  #
  # def prefixes
  #   object.prefixes
  # end
  #
  # def domains
  #   object.domains #object.domains.to_s.split(/\s*,\s*/).presence
  # end
  #
  # def member_id
  #  object.member_id
  # end
  #
  # def year
  #  object.year
  # end
  #
  # def created
  #   object.created
  # end
  #
  # def updated
  #   object.updated
  # end
end
