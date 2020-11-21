class ProviderPrefix < ApplicationRecord
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  belongs_to :provider, touch: true
  belongs_to :prefix, touch: true
  has_many :client_prefixes, dependent: :destroy
  has_many :clients, through: :client_prefixes

  before_create :set_uid

  validates_presence_of :provider, :prefix

  # use different index for testing
  if Rails.env.test?
    index_name "provider-prefixes-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "provider-prefixes-#{ENV['ES_PREFIX']}"
  else
    index_name "provider-prefixes"
  end

  mapping dynamic: "false" do
    indexes :id,                type: :keyword
    indexes :uid,               type: :keyword
    indexes :state,             type: :keyword
    indexes :provider_id,       type: :keyword
    indexes :provider_id_and_name, type: :keyword
    indexes :consortium_id,     type: :keyword
    indexes :prefix_id,         type: :keyword
    indexes :client_ids,        type: :keyword
    indexes :client_prefix_ids, type: :keyword
    indexes :created_at,        type: :date
    indexes :updated_at,        type: :date

    # index associations
    indexes :provider,           type: :object
    indexes :prefix,             type: :object, properties: {
      id: { type: :keyword },
      uid: { type: :keyword },
      provider_ids: { type: :keyword },
      client_ids: { type: :keyword },
      state: { type: :keyword },
      prefix: { type: :text },
      created_at: { type: :date },
    }
    indexes :clients,            type: :object
    indexes :client_prefixes,    type: :object
  end

  def as_indexed_json(options = {})
    {
      "id" => uid,
      "uid" => uid,
      "provider_id" => provider_id,
      "provider_id_and_name" => provider_id_and_name,
      "consortium_id" => consortium_id,
      "prefix_id" => prefix_id,
      "client_ids" => client_ids,
      "client_prefix_ids" => client_prefix_ids,
      "state" => state,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "provider" => provider.try(:as_indexed_json, exclude_associations: true),
      "prefix" => options[:exclude_associations] ? nil : prefix.try(:as_indexed_json, exclude_associations: true),
      "clients" => options[:exclude_associations] ? nil : clients.map { |m| m.try(:as_indexed_json, exclude_associations: true) },
      "client_prefixes" => options[:exclude_associations] ? nil : client_prefixes.map { |m| m.try(:as_indexed_json, exclude_associations: true) },
    }
  end

  def self.query_aggregations
    {
      states: { terms: { field: "state", size: 2, min_doc_count: 1 } },
      years: { date_histogram: { field: "created_at", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
               aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } },
      providers: { terms: { field: "provider_id_and_name", size: 10, min_doc_count: 1 } },
    }
  end

  def consortium_id
    provider.consortium_id.downcase if provider.consortium_id.present?
  end

  # convert external id / internal id
  def provider_id
    provider.symbol.downcase
  end

  def provider_id_and_name
    "#{provider_id}:#{provider.name}" if provider.present?
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

  def client_prefix_ids
    client_prefixes.pluck(:uid)
  end

  def state
    if client_prefix_ids.present?
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
