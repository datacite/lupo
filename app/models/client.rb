class Client < ActiveRecord::Base

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
  self.table_name = "datacentre"

  alias_attribute :flipper_id, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  attr_readonly :symbol
  delegate :symbol, to: :provider, prefix: true
  attr_accessor :password_input

  validates_presence_of :symbol, :name, :contact_name, :contact_email
  validates_uniqueness_of :symbol, message: "This Client ID has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_inclusion_of :role_name, :in => %w( ROLE_DATACENTRE ), :message => "Role %s is not included in the list"
  validates_associated :provider
  validate :check_id, :on => :create
  validate :freeze_symbol, :on => :update
  strip_attributes

  belongs_to :provider, foreign_key: :allocator
  has_many :dois, foreign_key: :datacentre
  has_many :client_prefixes, foreign_key: :datacentre, dependent: :destroy
  has_many :prefixes, through: :client_prefixes
  has_many :provider_prefixes, through: :client_prefixes

  before_validation :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  after_create :set_test_prefix, unless: Proc.new { Rails.env.test? }
  after_create :send_welcome_email, unless: Proc.new { Rails.env.test? }

  attr_accessor :target_id

  # use different index for testing
  index_name Rails.env.test? ? "clients-test" : "clients"

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
      indexes :symbol,        type: :keyword
      indexes :provider_id,   type: :keyword
      indexes :repository_id, type: :keyword
      indexes :prefix_ids,    type: :keyword
      indexes :name,          type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :contact_name,  type: :text
      indexes :contact_email, type: :text, fields: { keyword: { type: "keyword" }}
      indexes :re3data,       type: :keyword
      indexes :version,       type: :integer
      indexes :is_active,     type: :keyword
      indexes :domains,       type: :text
      indexes :year,          type: :integer
      indexes :url,           type: :text, fields: { keyword: { type: "keyword" }}
      indexes :cache_key,     type: :keyword
      indexes :created,       type: :date
      indexes :updated,       type: :date
      indexes :deleted_at,    type: :date

      # include parent objects
      indexes :provider,      type: :object
      indexes :repository,    type: :object
    end
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "provider_id" => provider_id,
      "repository_id" => repository_id,
      "prefix_ids" => prefix_ids,
      "name" => name,
      "symbol" => symbol,
      "year" => year,
      "contact_name" => contact_name,
      "contact_email" => contact_email,
      "domains" => domains,
      "url" => url,
      "is_active" => is_active,
      "password" => password,
      "cache_key" => cache_key,
      "created" => created,
      "updated" => updated,
      "deleted_at" => deleted_at,
      "provider" => provider.as_indexed_json,
      "repository" => repository
    }
  end

  def self.query_fields
    ['symbol^10', 'name^10', 'contact_name^10', 'contact_email^10', 'domains', 'url', 'repository.software.name^3', '_all']
  end

  def self.query_aggregations
    {
      years: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      providers: { terms: { field: 'provider_id', size: 15, min_doc_count: 1 } }
    }
  end

  def uid
    symbol.downcase
  end

  # workaround for non-standard database column names and association
  def provider_id
    provider_symbol.downcase
  end

  def provider_id=(value)
    r = cached_provider_response(value)
    return nil unless r.present?

    write_attribute(:allocator, r.id)
  end

  def prefix_ids
    prefixes.pluck(:prefix)
  end

  def repository_id
    re3data
  end

  def repository_id=(value)
    write_attribute(:re3data, value)
  end

  def repository
    OpenStruct.new(cached_repository_response(re3data)) if re3data.present?
  end

  def target_id=(value)
    c = self.class.find_by_id(value)
    return nil unless c.present?

    target = c.records.first

    dois.find_each do |doi|
      TransferJob.perform_later(doi.doi, target_id: target.id)
    end

    # update DOI count for source and target client
    cached_doi_count(force: true)
    target.cached_doi_count(force: true)
  end

  def cache_key
    "clients/#{uid}-#{updated.iso8601}"
  end

  def password_input=(value)
    write_attribute(:password, encrypt_password_sha256(value)) if value.present?
  end

  # backwards compatibility
  def member
    cached_member_response(provider_id) if provider_id.present?
  end

  def year
    created_at.year if created_at.present?
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "symbol" => symbol,
      "name" => name,
      "contact-name" => contact_name,
      "contact-email" => contact_email,
      "url" => url,
      "re3data" => re3data,
      "domains" => domains,
      "provider-id" => provider_id,
      "prefixes" => prefixes.map { |p| p.prefix },
      "is-active" => is_active == "\x01",
      "version" => version,
      "created" => created.iso8601,
      "updated" => updated.iso8601,
      "deleted_at" => deleted_at ? deleted_at.iso8601 : nil }

    { "id" => symbol.downcase, "type" => "clients", "attributes" => attributes }
  end

  protected

  def freeze_symbol
    errors.add(:symbol, "cannot be changed") if symbol_changed?
  end

  def check_id
    if symbol && symbol.split(".").first != provider.symbol
      errors.add(:symbol, ", Your Client ID must include the name of your provider. Separated by a dot '.' ")
    end
  end

  def user_url
    ENV["VOLPINO_URL"] + "/users?client-id=" + symbol.downcase
  end

  private

  def set_test_prefix
    prefixes << cached_prefix_response("10.5072")
  end

  def set_defaults
    self.contact_name = "" unless contact_name.present?
    self.domains = "*" unless domains.present?
    self.is_active = is_active ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 0
    self.role_name = "ROLE_DATACENTRE" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end
end
