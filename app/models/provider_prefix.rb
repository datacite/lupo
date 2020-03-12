require 'base32/url'

class ProviderPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  self.table_name = "allocator_prefixes"

  belongs_to :provider, foreign_key: :allocator, inverse_of: :provider_prefixes
  belongs_to :prefix, foreign_key: :prefixes, inverse_of: :provider_prefixes
  has_many :client_prefixes, foreign_key: :allocator_prefixes, dependent: :destroy, inverse_of: :provider_prefix
  has_many :clients, through: :client_prefixes

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at 

  before_create :set_id
  before_create { self.created_at = Time.zone.now.utc.iso8601 }
  before_save { self.updated_at = Time.zone.now.utc.iso8601 }

  scope :query, ->(query) { where("prefix.prefix like ?", "%#{query}%") }

  # use base32-encode id as uid, with pretty formatting
  def uid
    Base32::URL.encode(id, split: 4, length: 16)
  end

  # workaround for non-standard database column names and association
  def provider_id
    provider.symbol.downcase if provider.present?
  end

  # workaround for non-standard database column names and association
  def provider_id=(value)
    r = Provider.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    self.allocator = r.id
  end

  def prefix_id
    prefix.prefix
  end

  def client_ids
    clients.pluck(:symbol).map(&:downcase)
  end

  # workaround for non-standard database column names and association
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.prefixes = r.id
  end

  def self.state(state)
    case state
    when "without-client" then where.not(prefixes: ClientPrefix.pluck(:prefixes)).distinct
    when "with-client" then joins(:client_prefixes).distinct
    end
  end

  private

  # random number that fits into MySQL bigint field (8 bytes)
  def set_id
    self.id = SecureRandom.random_number(9223372036854775807)
  end
end
