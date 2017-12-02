class ClientSerializer < ActiveModel::Serializer
  cache key: 'client'

  attributes :name, :symbol, :year, :contact_name, :contact_email, :domains, :is_active, :password, :created, :updated

  has_many :prefixes, join_table: "datacentre_prefixes"
  belongs_to :provider
  belongs_to :repository, serializer: RepositorySerializer

  def id
    object.symbol.downcase
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end

  def password
    object.password.present? ? "yes" : nil
  end

  def provider_id
    object.provider_symbol
  end

  def created
    object.created.iso8601
  end

  def updated
    object.updated.iso8601
  end

  # def domains
  #   object.domains.to_s.split(/\s*,\s*/).presence
  # end
end
