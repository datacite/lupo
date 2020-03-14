class ClientPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  belongs_to :client
  belongs_to :prefix
  belongs_to :provider_prefix

  before_create :set_uid
  before_validation :set_provider_prefix_id

  # use different index for testing
  index_name Rails.env.test? ? "client-prefixes-test" : "client-prefixes"

  mapping dynamic: 'false' do
    indexes :id,                 type: :keyword
    indexes :uid,                type: :keyword
    indexes :provider_id,        type: :keyword
    indexes :client_id,          type: :keyword
    indexes :prefix_id,          type: :keyword
    indexes :provider_prefix_id, type: :keyword
    indexes :created_at,         type: :date
    indexes :updated_at,         type: :date

    # index associations
    indexes :client,             type: :object
    indexes :provider,           type: :object
    indexes :prefix,             type: :object
    indexes :provider_prefix,    type: :object
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "provider_id" => provider_id,
      "client_id" => client_id,
      "prefix_id" => prefix_id,
      "provider_prefix_id" => provider_prefix_id,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "client" => client.try(:as_indexed_json),
      "provider" => provider.try(:as_indexed_json),
      "prefix" => prefix.try(:as_indexed_json),
      "provider_prefix" => provider_prefix.try(:as_indexed_json),
    }
  end

  def self.query_aggregations
    {
      # states: { terms: { field: 'aasm_state', size: 15, min_doc_count: 1 } },
      years: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_ids', size: 15, min_doc_count: 1 } },
      clients: { terms: { field: 'client_ids', size: 15, min_doc_count: 1 } },
    }
  end

  def self.query_fields
    ['uid^10', '_all']
  end

  # convert external id / internal id
  def client_id
    client.symbol.downcase
  end

  # convert external id / internal id
  def client_id=(value)
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    self.client_id = r.id
  end

  # convert external id / internal id
  def prefix_id
    prefix.uid
  end

  # convert external id / internal id
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.prefix_id = r.id
  end

  def provider_id
    client.provider_id
  end

  def provider
    client.provider
  end

  def provider_prefix_id
    provider_prefix.uid
  end

  private

  # uuid for public id
  def set_uid
    self.uid = SecureRandom.uuid
  end

  def set_provider_prefix_id
    return nil unless provider_id.present?
    
    r = ProviderPrefix.joins(:provider).where('allocator.symbol = ?', provider_id).where(prefix_id: prefix_id).first
    self.provider_prefix_id = r.id if r.present?
  end
end
