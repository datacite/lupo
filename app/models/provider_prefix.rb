class ProviderPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  belongs_to :provider
  belongs_to :prefix
  has_many :client_prefixes, dependent: :destroy
  has_many :clients, through: :client_prefixes

  before_create :set_uid

  validates_presence_of :provider, :prefix

  # use different index for testing
  index_name Rails.env.test? ? "provider-prefixes-test" : "provider-prefixes"

  mapping dynamic: "false" do
    indexes :id,            type: :keyword
    indexes :uid,           type: :keyword
    indexes :state,         type: :keyword
    indexes :provider_id,   type: :keyword
    indexes :consortium_id, type: :keyword
    indexes :prefix_id,     type: :keyword
    indexes :client_ids,    type: :keyword
    indexes :created_at,    type: :date
    indexes :updated_at,    type: :date

    # index associations
    indexes :provider,           type: :object
    indexes :prefix,             type: :object
    indexes :clients,            type: :object
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "provider_id" => provider_id,
      "consortium_id" => consortium_id,
      "prefix_id" => prefix_id,
      "client_ids" => client_ids,
      "state" => state,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "provider" => provider.try(:as_indexed_json),
      "prefix" => prefix.try(:as_indexed_json),
      "clients" => clients.map { |m| m.try(:as_indexed_json) },
    }
  end

  def self.query_aggregations
    {
      states: { terms: { field: 'state', size: 2, min_doc_count: 1 } },
      years: { date_histogram: { field: 'created_at', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_id', size: 15, min_doc_count: 1 } },
    }
  end

  def self.query_fields
    ["uid^10", "provider_id", "prefix_id", "_all"]
  end

  def consortium_id
    provider.consortium_id.downcase if provider.consortium_id.present?
  end

  # convert external id / internal id
  def provider_id
    provider.symbol.downcase
  end

  # convert external id / internal id
  def provider_id=(value)
    r = Provider.where(symbol: value).first
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:provider_id, r.id)
  end

  # convert external id / internal id
  def prefix_id
    prefix.uid
  end

  # convert external id / internal id
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:prefix_id, r.id)
  end

  def client_ids
    clients.pluck(:symbol).map(&:downcase)
  end

  def state
    if client_ids.present?
      "with-repository"
    else
      "without-repository"
    end
  end

  private

  # uuid for public id
  def set_uid
    self.uid = SecureRandom.uuid
  end
end
