require "countries"

class Member < ActiveRecord::Base
  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "allocator"
  attribute :provider_type
  alias_attribute :uid, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :uid, :name, :contact_email, :country_code
  validates_uniqueness_of :uid, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Role %s is not included in the list", if: :role_name?

  has_many :clients
  alias_attribute :clients, :clients

  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator

  before_validation :set_region, :set_defaults, :set_provider_type
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }
  accepts_nested_attributes_for :prefixes

  scope :query, ->(query) { where("symbol like ? OR name like ?", "%#{query}%", "%#{query}%") }

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
    "#{ENV['CDN_URL']}/images/providers/#{uid.downcase}.png"
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

  def set_provider_type
    if doi_quota_allowed != 0
      r = "allocating"
    else
      r = "non_allocating"
    end
    write_attribute(:provider_type, r)
  end

  def set_defaults
    self.contact_name = "" unless contact_name.present?
    self.role_name = "ROLE_ALLOCATOR" unless role_name.present?
    self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
    self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
  end
end
