require 'base32/url'

class ProviderPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  belongs_to :provider
  belongs_to :prefix
  has_many :client_prefixes, dependent: :destroy
  has_many :clients, through: :client_prefixes

  delegate :symbol, to: :provider, prefix: true

  before_create :set_uid

  scope :query, ->(query) { where("prefix.uid like ?", "%#{query}%") }

  # workaround for non-standard database column names and association
  def provider_id
    provider.symbol.downcase if provider.present?
  end

  # workaround for non-standard database column names and association
  def provider_id=(value)
    r = Provider.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    self.provider_id = r.id
  end

  def prefix_id
    prefix.uid if prefix.present?
  end

  # workaround for non-standard database column names and association
  def prefix_id=(value)
    r = cached_prefix_response(value)
    fail ActiveRecord::RecordNotFound unless r.present?

    self.prefix_id = r.id
  end

  def client_ids
    clients.pluck(:symbol).map(&:downcase)
  end

  def self.state(state)
    case state
    when "without-client" then where.not(prefix_id: ClientPrefix.pluck(:prefix_id)).distinct
    when "with-client" then joins(:client_prefixes).distinct
    end
  end

  private

  # uuid for public id
  def set_uid
    self.uid = SecureRandom.uuid
  end
end
