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

  include Elasticsearch::Model

  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "allocator"
  alias_attribute :flipper_id, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  attr_readonly :symbol
  attr_accessor :password_input

  validates_presence_of :symbol, :name, :contact_name, :contact_email
  validates_uniqueness_of :symbol, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_MEMBER ROLE_ADMIN ROLE_DEV ), :message => "Role %s is not included in the list"
  validates_inclusion_of :institution_type, :in => %w(national_organization academic_institution research_institution government_organization publisher association service_provider), :message => "Institution type %s is not included in the list", if: :institution_type?
  validate :freeze_symbol, :on => :update

  before_validation :set_region

  strip_attributes

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

  #default_scope { where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_DEV')").where(deleted_at: nil) }

  #scope :query, ->(query) { where("allocator.symbol like ? OR allocator.name like ?", "%#{query}%", "%#{query}%") }

  # use different index for testing
  index_name Rails.env.test? ? "providers-test" : "providers"

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: 'keyword', filter: %w(lowercase ascii_folding) }
      },
      filter: { ascii_folding: { type: 'asciifolding', preserve_original: true } }
    }
  } do
    mapping dynamic: 'false' do
      indexes :id,            type: :keyword
      indexes :uid,           type: :keyword
      indexes :symbol,        type: :keyword
      indexes :name,          type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :contact_name,  type: :text
      indexes :contact_email, type: :text, fields: { keyword: { type: "keyword" }}
      indexes :version,       type: :integer
      indexes :is_active,     type: :keyword
      indexes :year,          type: :integer
      indexes :description,   type: :text
      indexes :website,       type: :text, fields: { keyword: { type: "keyword" }}
      indexes :phone,         type: :text
      indexes :logo_url,      type: :text
      indexes :region,        type: :keyword
      indexes :institution_type, type: :keyword
      indexes :member_type,   type: :keyword
      indexes :country_code,  type: :keyword
      indexes :role_name,     type: :keyword
      indexes :cache_key,     type: :keyword
      indexes :joined,        type: :date
      indexes :created,       type: :date
      indexes :updated,       type: :date
      indexes :deleted_at,    type: :date
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "name" => name,
      "symbol" => symbol,
      "year" => year,
      "contact_name" => contact_name,
      "contact_email" => contact_email,
      "is_active" => is_active,
      "description" => description,
      "website" => website,
      "phone" => phone,
      "region" => region,
      "country_code" => country_code,
      "logo_url" => logo_url,
      "institution_type" => institution_type,
      "member_type" => member_type,
      "role_name" => role_name,
      "password" => password,
      "cache_key" => cache_key,
      "joined" => joined,
      "created" => created,
      "updated" => updated,
      "deleted_at" => deleted_at
    }
  end

  def self.query_fields
    ['symbol^10', 'name^10', 'contact_name^10', 'contact_email^10', '_all']
  end
  
  def self.query_aggregations
    {
      years: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      regions: { terms: { field: 'region', size: 10, min_doc_count: 1 } }
    }
  end

  def uid
    symbol.downcase
  end
  
  def cache_key
    "providers/#{uid}-#{updated.iso8601}"
  end

  def year
    joined.year if joined.present?
  end

  # def country=(value)
  #   Rails.logger.debug value.inspect
  #   write_attribute(:country_code, value["code"]) if value.present?
  # end

  def country_name
    ISO3166::Country[country_code].name if country_code.present?
  end

  def set_region
    if country_code.present?
      r = ISO3166::Country[country_code].world_region
    else
      r = nil
    end
    write_attribute(:region, r)
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia Pacific",
      "EMEA" => "EMEA" }
  end

  def region_human_name
    regions[region]
  end

  def logo_url
    "#{ENV['CDN_URL']}/images/members/#{logo}" if logo.present?
  end

  def password_input=(value)
    write_attribute(:password, encrypt_password_sha256(value)) if value.present?
  end

  def member_type
    if role_name == "ROLE_ALLOCATOR"
      "provider"
    elsif role_name == "ROLE_MEMBER"
      "member_only"
    end
  end

  def client_ids
    clients.where(deleted_at: nil).pluck(:symbol).map(&:downcase)
  end

  def prefix_ids
    prefixes.pluck(:prefix).map { |p| p != "10.5072" }
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

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "symbol" => symbol,
      "name" => name,
      "website" => website,
      "contact-name" => contact_name,
      "contact-email" => contact_email,
      "contact-phone" => phone,
      "prefixes" => prefixes.map { |p| p.prefix },
      "country-code" => country_code,
      "role_name" => role_name,
      "description" => description,
      "is-active" => is_active == "\x01",
      "version" => version,
      "joined" => joined && joined.iso8601,
      "created" => created.iso8601,
      "updated" => updated.iso8601,
      "deleted_at" => deleted_at ? deleted_at.iso8601 : nil }

    { "id" => symbol.downcase, "type" => "providers", "attributes" => attributes }
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
    self.version = version.present? ? version + 1 : 0
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_ALLOCATOR" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end
end
