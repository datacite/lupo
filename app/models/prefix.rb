class Prefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "prefix"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :prefix
  validates_uniqueness_of :prefix
  validates_format_of :prefix, :with => /\A10\.\d{4,9}\z/

  has_many :client_prefixes, foreign_key: :prefixes
  has_many :clients, through: :client_prefixes
  has_many :provider_prefixes, foreign_key: :prefixes
  has_many :providers, through: :provider_prefixes

  before_validation :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("prefix like ?", "%#{query}%") }

  def registration_agency
    "DataCite"
  end

  # # workaround for non-standard database column names and association
  # def client_ids=(values)
  #   ids = Client.where(symbol: values).pluck(:id)
  #   association(:clients).ids_writer ids
  # end
  #
  # # workaround for non-standard database column names and association
  # def provider_ids=(values)
  #   ids = Provider.where(symbol: values).pluck(:id)
  #   association(:providers).ids_writer ids
  # end

  def set_defaults
    self.version = 0
  end

  def self.state(state)
    case state
    when "unassigned" then where.not(id: ProviderPrefix.pluck(:prefixes))
    when "without-client" then joins(:providers).where.not(id: ClientPrefix.pluck(:prefixes)).distinct
    when "with-client" then joins(:clients).distinct
    end
  end
end
