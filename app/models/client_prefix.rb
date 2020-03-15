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

  validates_presence_of :client, :prefix, :provider_prefix

  # use different index for testing
  index_name Rails.env.test? ? "client-prefixes-test" : "client-prefixes"

  mapping dynamic: "false" do
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
    logger.warn value.inspect
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:client_id, r.id)
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

  def provider_id
    client.provider_id if client.present?
  end

  def provider
    client.provider if client.present?
  end

  def provider_prefix_id
    provider_prefix.uid
  end

  # convert external id / internal id
  def provider_prefix_id=(value)
    r = ProviderPrefix.where(uid: value).first
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:provider_prefix_id, r.id)
  end

  private

  # uuid for public id
  def set_uid
    self.uid = SecureRandom.uuid
  end
end
