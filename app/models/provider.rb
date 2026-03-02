# frozen_string_literal: true

require "countries"

class Provider < ApplicationRecord
  audited except: %i[
    globus_uuid
    system_email
    group_email
    technical_contact
    secondary_technical_contact
    service_contact
    secondary_service_contact
    billing_contact
    secondary_billing_contact
    voting_contact
    billing_information
    salesforce_id
    password
    updated
    experiments
    comments
    logo
    version
    doi_quota_allowed
    doi_quota_used
    doi_estimate
    created
  ]

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

  has_attached_file :logo,
                    styles: { medium: ["500x200", :png] },
                    default_style: :medium,
                    default_url: "/images/members/default.png"

  validates_attachment :logo,
                       content_type: {
                         content_type: %w[image/jpg image/jpeg image/png],
                       }

  # define table and attribute names
  # uid is used as unique identifier, mapped to id in serializer
  self.table_name = "allocator"
  alias_attribute :flipper_id, :symbol
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  attr_readonly :symbol
  attr_reader :from_salesforce

  delegate :salesforce_id, to: :consortium, prefix: true, allow_nil: true

  validates_presence_of :symbol, :name, :display_name, :system_email
  validates_uniqueness_of :symbol, message: "This name has already been taken"
  validates_format_of :symbol,
                      with: /\A([A-Z]+)\Z/,
                      message: "should only contain capital letters"
  validates_length_of :symbol, minimum: 2, maximum: 8
  validates_format_of :system_email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
                      message: "system_email should be an email"
  validates_format_of :group_email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
                      if: :group_email?,
                      message: "group_email should be an email"
  validates_format_of :website,
                      with: %r{https?://\S+},
                      if: :website?,
                      message: "Website should be a url"
  validates_format_of :salesforce_id,
                      with: /[a-zA-Z0-9]{18}/,
                      message: "wrong format for salesforce id",
                      if: :salesforce_id?
  validates_inclusion_of :role_name,
                         in: %w[
                           ROLE_FOR_PROFIT_PROVIDER
                           ROLE_CONTRACTUAL_PROVIDER
                           ROLE_CONSORTIUM
                           ROLE_CONSORTIUM_ORGANIZATION
                           ROLE_ALLOCATOR
                           ROLE_MEMBER
                           ROLE_ADMIN
                           ROLE_DEV
                         ],
                         message: "Role %s is not included in the list"
  validates_inclusion_of :organization_type,
                         in: %w[
                           researchInstitution
                           academicInstitution
                           governmentAgency
                           nationalInstitution
                           professionalSociety
                           publisher
                           serviceProvider
                           internationalOrganization
                           other
                         ],
                         message:
                           "organization type %s is not included in the list",
                         if: :organization_type?
  validates_inclusion_of :non_profit_status,
                         in: %w[non-profit for-profit],
                         message:
                           "non-profit status '%s' is not included in the list"
  validates_inclusion_of :focus_area,
                         in: %w[
                           naturalSciences
                           engineeringAndTechnology
                           medicalAndHealthSciences
                           agriculturalSciences
                           socialSciences
                           humanities
                           general
                         ],
                         message: "focus area %s is not included in the list",
                         if: :focus_area?
  validate :freeze_symbol, on: :update
  validate :can_be_in_consortium
  validate :uuid_format, if: :globus_uuid?
  validates_format_of :ror_id,
                      with: %r{\Ahttps://ror\.org/0\w{6}\d{2}\z},
                      if: :ror_id?,
                      message: "ROR ID should be a url"
  validates_format_of :twitter_handle,
                      with: /\A@[a-zA-Z0-9_]{1,15}\z/, if: :twitter_handle?

  validates_attachment_content_type :logo, content_type: /\Aimage/

  # validates :technical_contact, contact: true
  # validates :billing_contact, contact: true
  # validates :secondary_billing_contact, contact: true
  # validates :service_contact, contact: true
  # validates :voting_contact, contact: true
  # validates :billing_information, billing_information: true

  validates :doi_estimate, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  strip_attributes

  has_many :clients, foreign_key: :allocator
  has_many :dois, through: :clients
  has_many :provider_prefixes, dependent: :destroy
  has_many :prefixes, through: :provider_prefixes
  has_many :consortium_organizations,
           class_name: "Provider",
           primary_key: "symbol",
           foreign_key: "consortium_id",
           inverse_of: :consortium
  belongs_to :consortium,
             class_name: "Provider",
             primary_key: "symbol",
             inverse_of: :consortium_organizations,
             optional: true
  has_many :activities, as: :auditable, dependent: :destroy
  has_many :contacts

  # TODO get information from contact model instead storing in provider model
  # has_one :voting_contact, ->(contact) { where("'voting' in ?", Array.wrap(contact.role_name)) }
  # has_one :service_contact, ->(contact) { where("'service' in ?", Array.wrap(contact.role_name)) }
  # has_one :billing_contact, ->(contact) { where("'billing' in ?", Array.wrap(contact.role_name)) }

  before_validation :set_region, :set_defaults
  before_create { self.created = Time.zone.now.utc.iso8601 }
  before_save { self.updated = Time.zone.now.utc.iso8601 }

  accepts_nested_attributes_for :prefixes

  # use different index for testing
  if Rails.env.test?
    index_name "providers-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "providers-#{ENV['ES_PREFIX']}"
  else
    index_name "providers"
  end

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: {
          tokenizer: "keyword", filter: %w[lowercase ascii_folding]
        },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w[lowercase] },
      },
      filter: {
        ascii_folding: {
          type: "asciifolding", preserve_original: true
        },
      },
    },
  } do
    mapping dynamic: "false" do
      indexes :id, type: :keyword
      indexes :uid, type: :keyword, normalizer: "keyword_lowercase"
      indexes :symbol, type: :keyword
      indexes :globus_uuid, type: :keyword
      indexes :client_ids, type: :keyword
      indexes :prefix_ids, type: :keyword
      indexes :contact_ids, type: :keyword
      indexes :name,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text",
                  "analyzer": "string_lowercase",
                  "fielddata": true,
                },
              }
      indexes :display_name,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text",
                  "analyzer": "string_lowercase",
                  "fielddata": true,
                },
              }
      indexes :system_email,
              type: :text, fields: { keyword: { type: "keyword" } }
      indexes :group_email,
              type: :text, fields: { keyword: { type: "keyword" } }
      indexes :version, type: :integer
      indexes :is_active, type: :keyword
      indexes :year, type: :integer
      indexes :description, type: :text
      indexes :website, type: :text, fields: { keyword: { type: "keyword" } }
      indexes :logo_url, type: :text
      indexes :image, type: :text
      indexes :region, type: :keyword
      indexes :focus_area, type: :keyword
      indexes :organization_type, type: :keyword
      indexes :member_type, type: :keyword
      indexes :non_profit_status, type: :keyword
      indexes :consortium_id,
              type: :text,
              fields: {
                keyword: { type: "keyword" },
                raw: {
                  type: "text",
                  "analyzer": "string_lowercase",
                  "fielddata": true,
                },
              }
      indexes :consortium_organization_ids, type: :keyword
      indexes :country_code, type: :keyword
      indexes :role_name, type: :keyword
      indexes :cache_key, type: :keyword
      indexes :joined, type: :date
      indexes :twitter_handle, type: :keyword
      indexes :ror_id, type: :keyword
      indexes :salesforce_id, type: :keyword
      indexes :billing_information,
              type: :object,
              properties: {
                postCode: { type: :keyword },
                state: { type: :text },
                organization: { type: :text },
                department: { type: :text },
                city: { type: :text },
                country: { type: :keyword },
                address: { type: :text },
              }
      indexes :technical_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :secondary_technical_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :billing_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :secondary_billing_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :service_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :secondary_service_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :voting_contact,
              type: :object,
              properties: {
                uid: { type: :keyword },
                email: { type: :text },
                given_name: { type: :text },
                family_name: { type: :text },
                name: { type: :text },
              }
      indexes :has_required_contacts, type: :boolean
      indexes :created, type: :date
      indexes :updated, type: :date
      indexes :deleted_at, type: :date
      indexes :cumulative_years, type: :integer, index: "false"

      indexes :consortium, type: :object
      indexes :consortium_organizations, type: :object
      indexes :contacts, type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        provider_id: { type: :keyword, normalizer: "keyword_lowercase" },
        consortium_id: { type: :keyword, normalizer: "keyword_lowercase" },
        given_name: { type: :keyword, normalizer: "keyword_lowercase" },
        family_name: { type: :keyword, normalizer: "keyword_lowercase" },
        name: { type: :keyword, normalizer: "keyword_lowercase" },
        email: { type: :keyword, normalizer: "keyword_lowercase" },
        role_name: { type: :keyword, normalizer: "keyword_lowercase" },
        created_at: { type: :date },
        updated_at: { type: :date },
        deleted_at: { type: :date }
      }
      indexes :doi_estimate, type: :integer
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(options = {})
    {
      "id" => uid,
      "uid" => uid,
      "name" => name,
      "display_name" => display_name,
      "client_ids" => options[:exclude_associations] ? nil : client_ids,
      "prefix_ids" => options[:exclude_associations] ? nil : prefix_ids,
      "contact_ids" => options[:exclude_associations] ? nil : contact_ids,
      "symbol" => symbol,
      "year" => year,
      "system_email" => system_email,
      "group_email" => group_email,
      "is_active" => is_active,
      "description" => description,
      "website" => website,
      "region" => region,
      "country_code" => country_code,
      "logo_url" => logo_url,
      "focus_area" => focus_area,
      "organization_type" => organization_type,
      "member_type" => member_type,
      "non_profit_status" => non_profit_status,
      "consortium_id" => consortium_id,
      "consortium_organization_ids" =>
        options[:exclude_associations] ? nil : consortium_organization_ids,
      "role_name" => role_name,
      "password" => password,
      "cache_key" => cache_key,
      "joined" => joined.try(:iso8601),
      "twitter_handle" => twitter_handle,
      "ror_id" => ror_id,
      "salesforce_id" => salesforce_id,
      "globus_uuid" => globus_uuid,
      "billing_information" => {
        "address" => billing_address,
        "organization" => billing_organization,
        "department" => billing_department,
        "postCode" => billing_post_code,
        "state" => billing_state,
        "country" => billing_country,
        "city" => billing_city,
      },
      "technical_contact" => technical_contact,
      "secondary_technical_contact" => secondary_technical_contact,
      "billing_contact" => billing_contact,
      "secondary_billing_contact" => secondary_billing_contact,
      "service_contact" => service_contact,
      "secondary_service_contact" => secondary_service_contact,
      "voting_contact" => voting_contact,
      "has_required_contacts" => has_required_contacts,
      "created" => created.try(:iso8601),
      "updated" => updated.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
      "cumulative_years" => cumulative_years,
      "consortium" => consortium.try(:as_indexed_json),
      "contacts" =>
        if options[:exclude_associations]
          nil
        else
          contacts.map { |m| m.try(:as_indexed_json, exclude_associations: true) }
        end,
      "doi_estimate" => doi_estimate
    }
  end

  def self.query_fields
    %w[uid^10 symbol^10 name^5 system_email^5 group_email^5 _all]
  end

  def self.query_aggregations
    {
      years: {
        date_histogram: {
          field: "created",
          interval: "year",
          format: "year",
          order: { _key: "desc" },
          min_doc_count: 1,
        },
        aggs: { bucket_truncate: { bucket_sort: { size: 10 } } },
      },
      cumulative_years: {
        terms: {
          field: "cumulative_years",
          size: 20,
          min_doc_count: 1,
          order: { _count: "asc" },
        },
      },
      regions: { terms: { field: "region", size: 10, min_doc_count: 1 } },
      member_types: {
        terms: { field: "member_type", size: 10, min_doc_count: 1 },
      },
      organization_types: {
        terms: { field: "organization_type", size: 10, min_doc_count: 1 },
      },
      focus_areas: {
        terms: { field: "focus_area", size: 10, min_doc_count: 1 },
      },
      non_profit_statuses: {
        terms: { field: "non_profit_status", size: 10, min_doc_count: 1 },
      },
      has_required_contacts: {
        terms: { field: "has_required_contacts", size: 2, min_doc_count: 1 },
      },
    }
  end

  def csv
    provider = {
      name: name,
      provider_id: symbol,
      consortium_id: consortium.present? ? consortium.symbol : "",
      salesforce_id: salesforce_id,
      consortium_salesforce_id:
        consortium.present? ? consortium.salesforce_id : "",
      role_name: role_name,
      is_active: is_active == "\x01",
      description: description,
      website: website,
      region: region_human_name,
      country: country_code,
      logo_url: logo_url,
      focus_area: focus_area,
      organization_type: organization_type,
      member_type: member_type_label,
      system_email: system_email,
      group_email: group_email,

      technical_contact_email: technical_contact_email,
      technical_contact_given_name: technical_contact_given_name,
      technical_contact_family_name: technical_contact_family_name,
      secondary_technical_contact_email: secondary_technical_contact_email,
      secondary_technical_contact_given_name:
        secondary_technical_contact_given_name,
      secondary_technical_contact_family_name:
        secondary_technical_contact_family_name,
      service_contact_email: service_contact_email,
      service_contact_given_name: service_contact_given_name,
      service_contact_family_name: service_contact_family_name,
      secondary_service_contact_email: secondary_service_contact_email,
      secondary_service_contact_given_name:
        secondary_service_contact_given_name,
      secondary_service_contact_family_name:
        secondary_service_contact_family_name,
      voting_contact_email: voting_contact_email,
      voting_contact_given_name: voting_contact_given_name,
      voting_contact_family_name: voting_contact_family_name,
      billing_contact_email: billing_contact_email,
      billing_contact_given_name: billing_contact_given_name,
      billing_contact_family_name: billing_contact_family_name,
      secondary_billing_contact_email: secondary_billing_contact_email,
      secondary_billing_contact_given_name:
        secondary_billing_contact_given_name,
      secondary_billing_contact_family_name:
        secondary_billing_contact_family_name,

      billing_address: billing_address,
      billing_post_code: billing_post_code,
      billing_city: billing_city,
      billing_department: billing_department,
      billing_organization: billing_organization,
      billing_state: billing_state,
      billing_country: billing_country,

      twitter_handle: twitter_handle,
      ror_id: ror_id,
      created: created,
      updated: updated,
      deleted_at: deleted_at,
      doi_estimate: doi_estimate,
    }.values

    CSV.generate { |csv| csv << provider }
  end

  def uid
    symbol.downcase
  end

  def consortium_uid
    consortium_id.downcase
  end

  def from_salesforce=(value)
    @from_salesforce = (value.to_s == "true")
  end

  def consortium_organization_ids
    if consortium_organizations.present?
      consortium_organizations.pluck(:symbol).map(&:downcase)
    end
  end

  def cache_key
    "providers/#{uid}-#{updated.iso8601}"
  end

  def year
    joined.year if joined.present?
  end

  def technical_contact_email
    technical_contact.fetch("email", nil) if technical_contact.present?
  end

  def technical_contact_given_name
    technical_contact.fetch("given_name", nil) if technical_contact.present?
  end

  def technical_contact_family_name
    technical_contact.fetch("family_name", nil) if technical_contact.present?
  end

  def secondary_technical_contact_email
    if secondary_technical_contact.present?
      secondary_technical_contact.fetch("email", nil)
    end
  end

  def secondary_technical_contact_given_name
    if secondary_technical_contact.present?
      secondary_technical_contact.fetch("given_name", nil)
    end
  end

  def secondary_technical_contact_family_name
    if secondary_technical_contact.present?
      secondary_technical_contact.fetch("family_name", nil)
    end
  end

  def service_contact_email
    service_contact.fetch("email", nil) if service_contact.present?
  end

  def service_contact_given_name
    service_contact.fetch("given_name", nil) if service_contact.present?
  end

  def service_contact_family_name
    service_contact.fetch("family_name", nil) if service_contact.present?
  end

  def secondary_service_contact_email
    if secondary_service_contact.present?
      secondary_service_contact.fetch("email", nil)
    end
  end

  def secondary_service_contact_given_name
    if secondary_service_contact.present?
      secondary_service_contact.fetch("given_name", nil)
    end
  end

  def secondary_service_contact_family_name
    if secondary_service_contact.present?
      secondary_service_contact.fetch("family_name", nil)
    end
  end

  def voting_contact_email
    voting_contact.fetch("email", nil) if voting_contact.present?
  end

  def voting_contact_given_name
    voting_contact.fetch("given_name", nil) if voting_contact.present?
  end

  def voting_contact_family_name
    voting_contact.fetch("family_name", nil) if voting_contact.present?
  end

  def has_required_contacts
    if member_type == "consortium_organization"
      service_contact_email.present?
    else
      voting_contact_email.present? && service_contact_email.present? && billing_contact_email.present?
    end
  end

  def billing_department
    billing_information.fetch("department", nil) if billing_information.present?
  end

  def billing_organization
    if billing_information.present?
      billing_information.fetch("organization", nil)
    end
  end

  def billing_address
    billing_information.fetch("address", nil) if billing_information.present?
  end

  def billing_state
    billing_information.fetch("state", nil) if billing_information.present?
  end

  def billing_city
    billing_information.fetch("city", nil) if billing_information.present?
  end

  def billing_post_code
    billing_information.fetch("post_code", nil) if billing_information.present?
  end

  def billing_country
    billing_information.fetch("country", nil) if billing_information.present?
  end

  def billing_contact_email
    billing_contact.fetch("email", nil) if billing_contact.present?
  end

  def billing_contact_given_name
    billing_contact.fetch("given_name", nil) if billing_contact.present?
  end

  def billing_contact_family_name
    billing_contact.fetch("family_name", nil) if billing_contact.present?
  end

  def secondary_billing_contact_email
    if secondary_billing_contact.present?
      secondary_billing_contact.fetch("email", nil)
    end
  end

  def secondary_billing_contact_given_name
    if secondary_billing_contact.present?
      secondary_billing_contact.fetch("given_name", nil)
    end
  end

  def secondary_billing_contact_family_name
    if secondary_billing_contact.present?
      secondary_billing_contact.fetch("family_name", nil)
    end
  end

  def member_type_label
    member_type_labels[role_name]
  end

  def member_type_labels
    {
      "ROLE_MEMBER" => "Member Only",
      "ROLE_ALLOCATOR" => "Direct Member",
      "ROLE_CONSORTIUM" => "Consortium",
      "ROLE_CONSORTIUM_ORGANIZATION" => "Consortium Organization",
      "ROLE_CONTRACTUAL_PROVIDER" => "Contractual Member",
      "ROLE_ADMIN" => "DataCite Admin",
      "ROLE_DEV" => "Developer",
      "ROLE_FOR_PROFIT_PROVIDER" => "Direct Member",
    }
  end

  def member_type
    member_types[role_name]
  end

  def member_type=(value)
    role_name = member_types.invert.fetch(value, nil)
    write_attribute(:role_name, role_name) if role_name.present?
  end

  def member_types
    {
      "ROLE_MEMBER" => "member_only",
      "ROLE_ALLOCATOR" => "direct_member",
      "ROLE_CONSORTIUM" => "consortium",
      "ROLE_CONSORTIUM_ORGANIZATION" => "consortium_organization",
      "ROLE_CONTRACTUAL_PROVIDER" => "contractual_member",
      "ROLE_FOR_PROFIT_PROVIDER" => "for-profit_provider",
      "ROLE_DEV" => "developer",
    }
  end

  # count years account has been active. Ignore if deleted the same year as created
  def cumulative_years
    if deleted_at && deleted_at.year > created_at.year
      (created_at.year...deleted_at.year).to_a
    elsif deleted_at
      []
    else
      (created_at.year..Date.today.year).to_a
    end
  end

  # def country=(value)
  #   write_attribute(:country_code, value["code"]) if value.present?
  # end

  def country_name
    ISO3166::Country[country_code].name if country_code.present?
  end

  def billing_country_name
    ISO3166::Country[billing_country].try(:name) if billing_country.present?
  end

  def set_region
    r = ISO3166::Country[country_code].world_region if country_code.present?
    write_attribute(:region, r)
  end

  def regions
    { "AMER" => "Americas", "APAC" => "Asia Pacific", "EMEA" => "EMEA" }
  end

  def region_human_name
    regions[region]
  end

  def logo_url
    logo.url(:medium) if logo.present?
  end

  def password_input=(value)
    write_attribute(:password, encrypt_password_sha256(value)) if value.present?
  end

  def client_ids
    clients.where(deleted_at: nil).pluck(:symbol).map(&:downcase)
  end

  def prefix_ids
    prefixes.pluck(:uid)
  end

  def contact_ids
    contacts.where(deleted_at: nil).pluck(:uid)
  end

  def can_be_in_consortium
    if consortium_id && member_type != "consortium_organization"
      errors.add(
        :consortium_id,
        "The provider must be of member_type consortium_organization",
      )
    elsif consortium_id && consortium.member_type != "consortium"
      errors.add(
        :consortium_id,
        "The consortium must be of member_type consortium",
      )
    end
  end

  def uuid_format
    unless UUID.validate(globus_uuid)
      errors.add(:globus_uuid, "#{globus_uuid} is not a valid UUID")
    end
  end

  def freeze_symbol
    errors.add(:symbol, "cannot be changed") if symbol_changed?
  end

  def user_url
    ENV["VOLPINO_URL"] + "/users?provider-id=" + symbol.downcase
  end

  def activity_id_not_changed
    if activity_id_changed? && self.persisted?
      errors.add(:activity_id, "Change of activity_id not allowed!")
    end
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "symbol" => symbol,
      "salesforce_id" => salesforce_id,
      "consortium_salesforce_id" => consortium_salesforce_id,
      "parent_organization" => consortium_id.present? ? consortium_id.upcase : nil,
      "name" => name,
      "website" => website,
      "system_email" => system_email,
      "group_email" => group_email,
      "description" => description,
      "region" => region,
      "logo_url" => logo_url,
      "non_profit_status" => non_profit_status,
      "focus_area" => focus_area,
      "organization_type" => organization_type,
      "member_type" => member_type_label,
      "is_active" => is_active == "\x01",
      "billing_street" => billing_address,
      "billing_organization" => billing_organization,
      "billing_department" => billing_department,
      "billing_postal_code" => billing_post_code,
      "billing_state_code" => billing_state.present? ? billing_state.split("-").last : nil,
      "billing_country_code" => billing_country,
      "billing_country" => billing_country_name,
      "billing_city" => billing_city,
      "joined" => joined.try(:iso8601),
      "twitter_handle" => twitter_handle,
      "ror_id" => ror_id,
      "created" => created.try(:iso8601),
      "updated" => updated.try(:iso8601),
      "deleted_at" => deleted_at ? deleted_at.try(:iso8601) : nil,
      "doi_estimate" => doi_estimate,
    }

    {
      "id" => symbol.downcase, "type" => "providers", "attributes" => attributes
    }
  end

  def self.export(query: nil)
    query = query.present? ? query + " !role_name:ROLE_ADMIN !role_name:ROLE_DEV" : "!role_name:ROLE_ADMIN !role_name:ROLE_DEV"

    # Loop through all providers
    i = 0
    page = { size: 1_000, number: 1 }
    response = self.query(query, include_deleted: true, page: page)
    response.records.each do |provider|
      provider.send_provider_export_message(provider.to_jsonapi)
      i += 1
    end

    total = response.results.total
    total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

    # keep going for all pages
    page_num = 2
    while page_num <= total_pages
      page = { size: 1_000, number: page_num }
      response = self.query(query, include_deleted: true, page: page)
      response.records.each do |provider|
        provider.send_provider_export_message(provider.to_jsonapi)
        i += 1
      end
      page_num += 1
    end

    "#{i} providers exported."
  end

  private
    def set_region
      r = ISO3166::Country[country_code].world_region if country_code.present?
      write_attribute(:region, r)
    end

    def set_defaults
      self.symbol = symbol.upcase if symbol.present?
      self.is_active = is_active ? "\x01" : "\x00"
      self.version = version.present? ? version + 1 : 0
      self.role_name = "ROLE_ALLOCATOR" if role_name.blank?
      self.doi_quota_used = 0 unless doi_quota_used.to_i > 0
      self.doi_quota_allowed = -1 unless doi_quota_allowed.to_i > 0
      self.billing_information = {} if billing_information.blank?
      self.consortium_id = nil unless member_type == "consortium_organization"
      self.non_profit_status = "non-profit" if non_profit_status.blank?
      self.doi_estimate = doi_estimate.to_i

      # custom filename for attachment as data URLs don't support filenames
      if logo_content_type.present?
        self.logo_file_name =
          symbol.downcase + "." + logo_content_type.split("/").last
      end
    end
end
