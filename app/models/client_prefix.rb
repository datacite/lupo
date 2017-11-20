require 'base32/crockford'

class ClientPrefix < ApplicationRecord
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "datacentre_prefixes"

  belongs_to :client, foreign_key: :datacentre
  belongs_to :prefix, foreign_key: :prefixes
  belongs_to :provider_prefix, foreign_key: :allocator_prefixes

  delegate :symbol, to: :client, prefix: true

  before_create :set_id
  before_create { self.created_at = Time.zone.now.utc.iso8601 }
  before_save { self.updated_at = Time.zone.now.utc.iso8601 }
  before_validation :set_allocator_prefixes

  scope :query, ->(query) { includes(:prefix).where("prefix.prefix like ?", "%#{query}%") }

  # use base32-encode id as uid, with pretty formatting and checksum
  def uid
    Base32::Crockford.encode(id, split: 4, length: 16, checksum: true).downcase
  end

  # workaround for non-standard database column names and association
  def client_id
    client_symbol.downcase
  end

  # workaround for non-standard database column names and association
  def client_id=(value)
    r = cached_client_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.datacentre = r.id
  end

  # workaround for non-standard database column names and association
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.prefixes = r.id
  end

  # def provider_prefix_id=(value)
  #   r = ProviderPrefix.where(id: value).first
  #   self.allocator_prefixes = r.id if r.present?
  # end
  #
  # def provider_prefix_id
  #   client.symbol.split('.').first if client.present?
  # end

  private

  # random number that fits into MySQL bigint field (8 bytes)
  def set_id
    self.id = SecureRandom.random_number(9223372036854775807)
  end

  def set_allocator_prefixes
    provider_symbol = client.symbol.split('.').first
    r = ProviderPrefix.joins(:provider).where('allocator.symbol = ?', provider_symbol).where(prefixes: prefixes).first
    self.allocator_prefixes = r.id if r.present?
  end
end
