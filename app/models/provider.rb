require "countries"

class Provider < ActiveRecord::Base

  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for managing associated users
  include Userable

  # include helper module for setting password
  include Passwordable

  # include helper module for authentication
  include Authenticable


  # include helper module for Elasticsearch 
  include Indexable

  # include helper module for sending emails
  include Mailable

  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer

  self.table_name = "allocator"
  alias_attribute :uid, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  attr_readonly :uid, :symbol
  attr_accessor :password_input

  validates_presence_of :symbol, :name, :contact_name, :contact_email
  validates_uniqueness_of :symbol, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Role %s is not included in the list"
  validate :freeze_symbol, :on => :update

  has_many :clients, foreign_key: :allocator
  has_many :dois, through: :clients
  has_many :provider_prefixes, foreign_key: :allocator, dependent: :destroy
  has_many :prefixes, through: :provider_prefixes

  before_validation :set_region, :set_defaults
  before_create :set_test_prefix
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  after_create :send_welcome_email, unless: Proc.new { Rails.env.test? }

  accepts_nested_attributes_for :prefixes

  default_scope { where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_DEV')").where(deleted_at: nil) }

  scope :query, ->(query) { where("allocator.symbol like ? OR allocator.name like ?", "%#{query}%", "%#{query}%") }

  def year
    created.year
  end

  def country_name
    return nil unless country_code.present?

    ISO3166::Country[country_code].name
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia Pacific",
      "EMEA" => "EMEA" }
  end

  def region_name
    regions[region]
  end

  def logo_url
    "#{ENV['CDN_URL']}/images/members/#{symbol.downcase}.png"
  end

  def password_input=(value)
    write_attribute(:password, encrypt_password_sha256(value)) if value.present?
  end

  # cumulative count clients by year
  # count until the previous year if client has been deleted
  # show all clients for admin
  def client_count
    c = clients.unscoped
    c = c.where("datacentre.allocator = ?", id) if symbol != "ADMIN"
    c = c.pluck(:created, :deleted_at).reduce([]) do |sum, a|
      from = a[0].year
      to = a[1] ? a[1].year : Date.today.year + 1
      sum += (from...to).to_a
    end
    return [] if c.empty?

    c += (c.min..Date.today.year).to_a
    c.group_by { |a| a }
     .sort { |a, b| a.first <=> b.first }
     .map { |a| { "id" => a[0], "title" => a[0], "count" => a[1].count - 1 } }
  end

  # show provider count for admin
  def provider_count
    return nil if symbol != "ADMIN"

    p = Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_DEV')")
    p = p.pluck(:created, :deleted_at).reduce([]) do |sum, a|
      from = a[0].year
      to = a[1] ? a[1].year : Date.today.year + 1
      sum += (from...to).to_a
    end
    p += (p.min..Date.today.year).to_a
    p.group_by { |a| a }
     .sort { |a, b| a.first <=> b.first }
     .map { |a| { "id" => a[0], "title" => a[0], "count" => a[1].count - 1 } }
  end

  def freeze_symbol
    errors.add(:symbol, "cannot be changed") if self.symbol_changed?
  end

  def user_url
    ENV["VOLPINO_URL"] + "/users?provider-id=" + symbol.downcase
  end

  def self.push_to_index
    self.find_each do |provider|
      ElasticsearchJob.perform_later(provider.to_jsonapi, "index")
    end
  end

  def to_jsonapi
    attributes = self.attributes
    attributes["updated"]= attributes["updated"].iso8601
    attributes["created"]= attributes["created"].iso8601
    attributes["prefixes"] = self.prefixes.map {|p| p.prefix }.join(', ')
    params = { "data" => { "type" => "providers", "attributes" => attributes } }
    params
  end

  private

  def set_region
    if country_code.present?
      r = ISO3166::Country[country_code].world_region
    else
      r = nil
    end
    write_attribute(:region, r)
  end

  # def set_provider_type
  #   if doi_quota_allowed != 0
  #     r = "allocating"
  #   else
  #     r = "non_allocating"
  #   end
  #   write_attribute(:provider_type, r)
  # end

  def set_test_prefix
    return if Rails.env.test? || prefixes.where(prefix: "10.5072").first

    prefixes << cached_prefix_response("10.5072")
  end

  def set_defaults
    self.symbol = symbol.upcase if symbol.present?
    self.is_active = is_active ? "\x01" : "\x00"
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_ALLOCATOR" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end
end
