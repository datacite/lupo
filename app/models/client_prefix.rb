require 'base32/url'

class ClientPrefix < ActiveRecord::Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  belongs_to :client
  belongs_to :prefix
  belongs_to :provider_prefix

  before_create :set_uid
  before_validation :set_provider_prefix_id

  scope :query, ->(query) { includes(:prefix).where("prefix.uid like ?", "%#{query}%") }

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
  def repository_id
    client.symbol.downcase
  end

  # convert external id / internal id
  def repository_id=(value)
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
    return nil unless client.present?
    
    provider_symbol = client.symbol.split('.').first
    r = ProviderPrefix.joins(:provider).where('allocator.symbol = ?', provider_symbol).where(prefix_id: prefix_id).first
    self.provider_prefix_id = r.id if r.present?
  end
end
