class Member < ApplicationRecord
  require "countries"
  self.table_name = "allocator"
  # alias_attribute :created_at, :created
  # alias_attribute :updated_at, :updated
  attribute :member_id
  alias_attribute :member_id, :symbol
  has_many :datacenters
  validates_presence_of :name
  validates_uniqueness_of :member_id, message: "This member_id has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_format_of :logo, :with => /https?:\/\/[\S]+/ , if: :logo?, message: "Logo should be an url"
  validates_numericality_of :version, if: :version?
  validates_numericality_of :doi_quota_allowed, :version
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Role {{value}} is not included in the list", if: :role_name?
  validates_inclusion_of :country_code, :in => ISO3166::Country.all.map(&:alpha2), :message => "must be a 2 character country representation (ISO 3166-1)", if: :country_code?

  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator

  # after_create  :add_test_prefix

  def member_type
    return "allocating"  if doi_quota_allowed >= 0
    "non_allocating"
  end
end
