class ClientSerializer < ActiveModel::Serializer
  cache key: 'client'

  attributes :name, :year, :contact, :email, :domains, :is_active, :doi_count, :created, :updated

  has_many :prefixes, join_table: "datacentre_prefixes"
  belongs_to :provider

  def id
    object.symbol.downcase
  end

  def is_active
    object.is_active == "\u0001" ? true : false
  end

  def contact
    object.contact_name
  end

  def email
    object.contact_email
  end

  def provider_id
    object.provider_symbol
  end

  # def domains
  #   object.domains.to_s.split(/\s*,\s*/).presence
  # end
end
