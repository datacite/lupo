class Prefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  # include Indexable

  # include Elasticsearch::Model

  validates_presence_of :uid
  validates_uniqueness_of :uid
  validates_format_of :uid, :with => /\A10\.\d{4,9}\z/

  has_many :client_prefixes
  has_many :clients, through: :client_prefixes
  has_many :provider_prefixes
  has_many :providers, through: :provider_prefixes

  scope :query, ->(query) { where("uid like ?", "%#{query}%") }

  # use different index for testing
  # index_name Rails.env.test? ? "prefixes-test" : "prefixes"

  # mapping dynamic: 'false' do
  #   indexes :prefix,                         type: :keyword
  #   indexes :provider_ids,                   type: :keyword
  #   indexes :registration_agency,            type: :keyword
  #   indexes :created,                        type: :date
  #   indexes :updated_at,                     type: :date
  # end

  # def as_indexed_json(options={})
  #   {
  #     "prefix" => prefix,
  #     "provider_ids" => provider_ids,
  #     "registration_agency" => registration_agency,
  #     "created" => created,
  #     "updated_at" => updated_at
  #   }
  # end

  # def self.query_aggregations
  #   {
  #     #states: { terms: { field: 'aasm_state', size: 15, min_doc_count: 1 } },
  #     years: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
  #     providers: { terms: { field: 'provider_ids', size: 15, min_doc_count: 1 } }
  #   }
  # end

  # def self.query_fields
  #   ['prefix^10', '_all']
  # end

  def registration_agency
    "DataCite"
  end

  def client_ids
    clients.pluck(:symbol).map(&:downcase)
  end

  def provider_ids
    providers.pluck(:symbol).map(&:downcase)
  end

  def self.state(state)
    case state
    when "unassigned" then where.not(id: ProviderPrefix.pluck(:prefix_id))
    when "without-client" then joins(:providers).where.not(id: ClientPrefix.pluck(:prefix_id)).distinct
    when "with-client" then joins(:clients).distinct
    end
  end
end
