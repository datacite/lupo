require "countries"

class Member < ApplicationRecord
  # define table and attribute names
  # we rename name -> title, so that we can do symbol -> name
  # name is used as unique identifier for most of our records,
  # mapped to id in serializer
  self.table_name = "allocator"
  alias_attribute :title, :name
  alias_attribute :name, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated

  validates_presence_of :name, :title, :contact_email, :contact_name, :doi_quota_allowed, :doi_quota_used, :country_code
  validates_uniqueness_of :name, message: "This name has already been taken"
  validates_format_of :contact_email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: "contact_email should be an email"
  validates_format_of :website, :with => /https?:\/\/[\S]+/ , if: :website?, message: "Website should be an url"
  validates_numericality_of :doi_quota_allowed, :doi_quota_used
  validates_numericality_of :version, if: :version?
  validates_inclusion_of :role_name, :in => %w( ROLE_ALLOCATOR ROLE_ADMIN ROLE_DEV ), :message => "Role %s is not included in the list", if: :role_name?
  validates_inclusion_of :country_code, :in => ISO3166::Country.all.map(&:alpha2), :message => "must be a 2 character country representation (ISO 3166-1)", if: :country_code?

  has_many :datacenters
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "allocator_prefixes", foreign_key: :prefixes, association_foreign_key: :allocator

  # after_create  :add_test_prefix

  def member_type
    return "allocating" if doi_quota_allowed > 0

    "non_allocating"
  end
end
