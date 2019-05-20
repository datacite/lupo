require 'base32/url'

class ClientPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "datacentre_prefixes"

  belongs_to :client, foreign_key: :datacentre #, touch: true
  belongs_to :prefix, foreign_key: :prefixes
  belongs_to :provider_prefix, foreign_key: :allocator_prefixes

  delegate :symbol, to: :client, prefix: true

  before_create :set_id
  before_create { self.created_at = Time.zone.now.utc.iso8601 }
  before_save { self.updated_at = Time.zone.now.utc.iso8601 }
  before_validation :set_allocator_prefixes

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at

  scope :query, ->(query) { includes(:prefix).where("prefix.prefix like ?", "%#{query}%") }

  # use base32-encode id as uid, with pretty formatting and checksum
  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  # workaround for non-standard database column names and association
  def client_id
    client_symbol.downcase
  end

  # workaround for non-standard database column names and association
  def client_id=(value)
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    self.datacentre = r.id
  end

  def prefix_id
    prefix.prefix
  end

  # workaround for non-standard database column names and association
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.prefixes = r.id
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

  # random number that fits into MySQL bigint field (8 bytes)
  def set_id
    self.id = SecureRandom.random_number(9223372036854775807)
  end

  def set_allocator_prefixes
    return nil unless client.present?
    
    provider_symbol = client.symbol.split('.').first
    r = ProviderPrefix.joins(:provider).where('allocator.symbol = ?', provider_symbol).where(prefixes: prefixes).first
    self.allocator_prefixes = r.id if r.present?
  end
end
