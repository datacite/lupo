# frozen_string_literal: true

class Contact < ApplicationRecord
  strip_attributes

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  belongs_to :provider, touch: true

  before_create :set_uid

  delegate :consortium_id, to: :provider, allow_nil: true

  ROLES = %w[voting billing secondary_billing service secondary_service technical secondary_technical]

  validates_presence_of :provider
  validates_presence_of :email
  validates_format_of :email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
                      message: "email should be valid",
                      allow_blank: true
  validates :email, uniqueness: { scope: :provider_id,
            message: "should be unique per provider" }
  validate :check_role_name, if: :role_name?

  # use different index for testing
  if Rails.env.test?
    index_name "contacts-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "contacts-#{ENV['ES_PREFIX']}"
  else
    index_name "contacts"
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
      indexes :uid, type: :keyword
      indexes :provider_id, type: :keyword, normalizer: "keyword_lowercase"
      indexes :consortium_id, type: :keyword, normalizer: "keyword_lowercase"
      indexes :given_name, type: :keyword, normalizer: "keyword_lowercase"
      indexes :family_name, type: :keyword, normalizer: "keyword_lowercase"
      indexes :name, type: :keyword, normalizer: "keyword_lowercase"
      indexes :email, type: :keyword, normalizer: "keyword_lowercase"
      indexes :role_name, type: :keyword, normalizer: "keyword_lowercase"
      indexes :created_at, type: :date
      indexes :updated_at, type: :date
      indexes :deleted_at, type: :date

      # include parent objects
      indexes :provider,
              type: :object,
              properties: {
                id: { type: :keyword },
                uid: { type: :keyword },
                symbol: { type: :keyword },
                globus_uuid: { type: :keyword },
                client_ids: { type: :keyword },
                prefix_ids: { type: :keyword },
                name: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                display_name: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                system_email: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                group_email: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                version: { type: :integer },
                is_active: { type: :keyword },
                year: { type: :integer },
                description: { type: :text },
                website: {
                  type: :text, fields: { keyword: { type: "keyword" } }
                },
                logo_url: { type: :text },
                region: { type: :keyword },
                focus_area: { type: :keyword },
                organization_type: { type: :keyword },
                member_type: { type: :keyword },
                consortium_id: {
                  type: :text,
                  fields: {
                    keyword: { type: "keyword" },
                    raw: {
                      type: "text",
                      "analyzer": "string_lowercase",
                      "fielddata": true,
                    },
                  },
                },
                consortium_organization_ids: { type: :keyword },
                country_code: { type: :keyword },
                role_name: { type: :keyword },
                cache_key: { type: :keyword },
                joined: { type: :date },
                twitter_handle: { type: :keyword },
                ror_id: { type: :keyword },
                salesforce_id: { type: :keyword },
                billing_information: {
                  type: :object,
                  properties: {
                    postCode: { type: :keyword },
                    state: { type: :text },
                    organization: { type: :text },
                    department: { type: :text },
                    city: { type: :text },
                    country: { type: :text },
                    address: { type: :text },
                  },
                },
                technical_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_technical_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                billing_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_billing_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                service_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                secondary_service_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                voting_contact: {
                  type: :object,
                  properties: {
                    email: { type: :text },
                    given_name: { type: :text },
                    family_name: { type: :text },
                  },
                },
                created: { type: :date },
                updated: { type: :date },
                deleted_at: { type: :date },
                cumulative_years: { type: :integer, index: "false" },
                consortium: { type: :object },
                consortium_organizations: { type: :object },
              }
    end
  end

  def as_indexed_json(options = {})
    {
      "id" => uid,
      "uid" => uid,
      "given_name" => given_name,
      "family_name" => family_name,
      "name" => name,
      "email" => email,
      "role_name" => role_name,
      "provider_id" => provider_id,
      "consortium_id" => consortium_id,
      "created_at" => created_at.try(:iso8601),
      "updated_at" => updated_at.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
      "provider" =>
        if options[:exclude_associations]
          nil
        else
          provider.as_indexed_json(exclude_associations: true)
        end,
    }
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "uid" => uid,
      "given_name" => given_name,
      "family_name" => family_name,
      "name" => name,
      "email" => email,
      "role_name" => Array.wrap(role_name).map(&:classify),
      "provider_id" => provider_id,
      "consortium_id" => consortium_id,
      "created_at" => created_at.try(:iso8601),
      "updated_at" => updated_at.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
    }

    {
      "id" => uid, "type" => "contacts", "attributes" => attributes
    }
  end

  def self.query_fields
    %w[
      uid^10
      given_name^10
      family_name^10
      name^5
      email^10
      role_name^10
      _all
    ]
  end

  def self.query_aggregations
    {
      roles: {
        terms: { field: "role_name", size: 10, min_doc_count: 1 },
      },
    }
  end

  def check_role_name
    taken_roles = provider.contacts.reduce([]) do |sum, contact|
      sum += contact.role_name if contact.role_name.present?
      sum
    end - Array.wrap(attribute_was(:role_name)).compact

    Array.wrap(role_name).each do |r|
      errors.add(:role_name, "Role name '#{r}' is not included in the list of possible role names.") unless ROLES.include?(r)
      errors.add(:role_name, "Role name '#{r}' is already taken.") if taken_roles.include?(r)
    end
  end

  def name
    [given_name, family_name].compact.join(" ")
  end

  # workaround for non-standard database column names and association
  def provider_id
    provider.uid
  end

  def provider_id=(value)
    r = Provider.where(symbol: value).first
    return nil if r.blank?

    write_attribute(:provider_id, r.id)
  end

  def self.export
    Contact.all.find_each do |contact|
      contact.send_contact_export_message(contact.to_jsonapi)
    end
  end

  def self.import_from_providers
    Provider.all.find_each do |provider|
      if provider.voting_contact_email
        contact = Contact.where(email: provider.voting_contact_email).first_or_create
        if contact.update(
          email: provider.voting_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.voting_contact_given_name,
          family_name: provider.voting_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "voting").uniq)
          puts "Imported voting contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing voting contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.billing_contact_email
        contact = Contact.where(email: provider.billing_contact_email).first_or_create
        if contact.update(
          email: provider.billing_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.billing_contact_given_name,
          family_name: provider.billing_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "billing").uniq)
          puts "Imported billing contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing billing contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_billing_contact_email
        contact = Contact.where(email: provider.secondary_billing_contact_email).first_or_create
        if contact.update(
          email: provider.secondary_billing_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_billing_contact_given_name,
          family_name: provider.secondary_billing_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "secondary_billing").uniq)
          puts "Imported secondary billing contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing secondary technical contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.service_contact_email
        contact = Contact.where(email: provider.service_contact_email).first_or_create
        if contact.update(
          email: provider.service_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.service_contact_given_name,
          family_name: provider.service_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "service").uniq)
          puts "Imported service contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing service contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_service_contact_email
        contact = Contact.where(email: provider.secondary_service_contact_email).first_or_create
        if contact.update(
          email: provider.secondary_service_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_service_contact_given_name,
          family_name: provider.secondary_service_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "secondary_service").uniq)
          puts "Imported secondary service contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing secondary service contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.technical_contact_email
        contact = Contact.where(email: provider.technical_contact_email).first_or_create
        if contact.update(
          email: provider.technical_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.technical_contact_given_name,
          family_name: provider.technical_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "technical").uniq)
          puts "Imported technical contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing technical contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_technical_contact_email
        contact = Contact.where(email: provider.secondary_technical_contact_email).first_or_create
        if contact.update(
          email: provider.secondary_technical_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_technical_contact_given_name,
          family_name: provider.secondary_technical_contact_family_name,
          role_name: (Array.wrap(contact.role_name) << "secondary_technical").uniq)
          puts "Imported secondary technical contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing secondary technical contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
    end
  end

  private
    # uuid for public id
    def set_uid
      self.uid = SecureRandom.uuid if self.uid.blank?
    end
end
