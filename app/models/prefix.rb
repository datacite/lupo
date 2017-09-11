class Prefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "prefix"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :prefix
  validates_uniqueness_of :prefix
  validates_format_of :prefix, :with => /\A10\.\d{4,5}\z/

  has_and_belongs_to_many :clients, join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre, autosave: true
  has_and_belongs_to_many :providers, join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator, autosave: true

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("prefix like ?", "%#{query}%") }

  def registration_agency
    "DataCite"
  end

  # workaround for non-standard database column names and association
  def client_ids=(values)
    ids = Client.where(symbol: values).pluck(:id)
    association(:clients).ids_writer ids
  end

  # workaround for non-standard database column names and association
  def provider_ids=(values)
    ids = Provider.where(symbol: values).pluck(:id)
    association(:providers).ids_writer ids
  end
end
