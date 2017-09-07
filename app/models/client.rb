class Client < ActiveRecord::Base

  # include helper module for caching infrequently changing resources
  include Cacheable

  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "datacentre"

  attr_accessor :provider_id

  alias_attribute :uid, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :uid, :name, :contact_email
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_DATACENTRE ), :message => "Role %s is not included in the list"

  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :provider, class_name: 'Provider', foreign_key: :allocator
  has_many :datasets

  before_validation :set_defaults

  delegate :uid, to: :provider, prefix: true
  delegate :symbol, to: :provider, prefix: true

  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  default_scope { where(is_active: "\x01") }

  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

  def year
    created_at.year if created_at.present?
  end

  def doi_quota_exceeded
    unless doi_quota_allowed.to_i > 0
      errors.add(:doi_quota, "You have excceded your DOI quota. You cannot mint DOIs anymore")
    end
  end


  private

  def set_defaults
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_DATACENTRE" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
    set_allocator unless allocator.present?
  end

  def set_allocator
    r = cached_provider_response(provider_id.upcase)
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:allocator, r.id)
  end
end
