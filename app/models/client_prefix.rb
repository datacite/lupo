require 'base32/crockford'

class ClientPrefix < ApplicationRecord
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "datacentre_prefixes"

  belongs_to :client, foreign_key: :datacentre
  belongs_to :prefix, foreign_key: :prefixes

  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  before_create :set_id
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { includes(:prefix).where("prefix.prefix like ?", "%#{query}%") }

  # use base32-encode id as uid, with pretty formatting and checksum
  def uid
    Base32::Crockford.encode(id, split: 4, length: 16, checksum: true).downcase
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

  def provider
    client.provider
  end

  private

  # random number that fits into MySQL bigint field (8 bytes)
  def set_id
    self.id = SecureRandom.random_number(9223372036854775807)
  end
end
