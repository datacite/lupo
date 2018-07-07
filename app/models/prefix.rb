class Prefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

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

  # scope :query, ->(query) { where("prefix like ?", "%#{query}%") }

  # use different index for testing
  index_name Rails.env.test? ? "prefixes-test" : "prefixes"

  mapping dynamic: 'false' do
    indexes :prefix,                         type: :keyword
    indexes :provider_ids,                   type: :keyword
    indexes :registration_agency,            type: :keyword
    indexes :created,                        type: :date
    indexes :updated_at,                     type: :date
  end

  def as_indexed_json(options={})
    {
      "prefix" => prefix,
      "provider_ids" => provider_ids,
      "registration_agency" => registration_agency,
      "created" => created,
      "updated_at" => updated_at
    }
  end

  def self.query_aggregations
    {
      #states: { terms: { field: 'aasm_state', size: 15, min_doc_count: 1 } },
      years: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_ids', size: 15, min_doc_count: 1 } }
    }
  end

  def self.query_fields
    ['prefix^10', '_all']
  end

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
