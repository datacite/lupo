# frozen_string_literal: true

class Contact < ApplicationRecord
  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  belongs_to :provider, touch: true

  before_create :set_uid

  ROLES = %w[voting_contact billing_contact secondary_billing_contact service_contact secondary_service_contact technical_contact secondary_technical_contact]

  # validates_inclusion_of :role_name,
  #                        in: ROLES,
  #                        message: "Role %s is not included in the list of possible roles"

  validates_presence_of :provider
  validates_presence_of :email
  validates_format_of :email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
                      message: "email should be valid",
                      allow_blank: true

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
      indexes :uid, type: :keyword, normalizer: "keyword_lowercase"
      indexes :provider_id, type: :keyword
      indexes :given_name, type: :keyword
      indexes :family_name, type: :keyword
      indexes :name, type: :keyword
      indexes :email, type: :keyword
      indexes :roles, type: :keyword
      indexes :created_at, type: :date
      indexes :updated_at, type: :date
      indexes :deleted_at, type: :date
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
      "roles" => roles,
      "provider_id" => provider_id,
      "created_at" => created_at.try(:iso8601),
      "updated_at" => updated_at.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
    }
  end

  def self.query_fields
    %w[
      uid^10
      given_name^10
      family_name^10
      name^5
      email^10
      roles^10
      _all
    ]
  end

  def self.query_aggregations
    {
      roles: {
        terms: { field: "roles", size: 10, min_doc_count: 1 },
      },
    }
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

  def self.import_from_providers
    Provider.all.find_each do |provider|
      if provider.voting_contact_email
        contact = Contact.where(email: provider.voting_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.voting_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.voting_contact_given_name,
          family_name: provider.voting_contact_family_name,
          roles: [] << "voting_contact")
          puts "Imported voting contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing voting contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.billing_contact_email
        contact = Contact.where(email: provider.billing_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.billing_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.billing_contact_given_name,
          family_name: provider.billing_contact_family_name,
          roles: Array.wrap(contact.roles) << "billing_contact")
          puts "Imported billing contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing billing contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_billing_contact_email
        contact = Contact.where(email: provider.secondary_billing_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.secondary_billing_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_billing_contact_given_name,
          family_name: provider.secondary_billing_contact_family_name,
          roles: Array.wrap(contact.roles) << "secondary_billing_contact")
          puts "Imported secondary billing contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing secondary technical contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.service_contact_email
        contact = Contact.where(email: provider.service_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.service_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.service_contact_given_name,
          family_name: provider.service_contact_family_name,
          roles: Array.wrap(contact.roles) << "service_contact")
          puts "Imported service contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing service contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_service_contact_email
        contact = Contact.where(email: provider.secondary_service_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.secondary_service_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_service_contact_given_name,
          family_name: provider.secondary_service_contact_family_name,
          roles: Array.wrap(contact.roles) << "secondary_service_contact")
          puts "Imported secondary service contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing secondary service contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.technical_contact_email
        contact = Contact.where(email: provider.technical_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.technical_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.technical_contact_given_name,
          family_name: provider.technical_contact_family_name,
          roles: Array.wrap(contact.roles) << "technical_contact")
          puts "Imported technical contact #{contact.email} for provider #{provider.symbol}."
        else
          puts "Error importing technical contact #{contact.email} for provider #{provider.symbol}: #{contact.errors.messages.inspect}."
        end
      end
      if provider.secondary_technical_contact_email
        contact = Contact.where(email: provider.secondary_technical_contact_email, provider_id: provider.id).first_or_create
        if contact.update(
          email: provider.secondary_technical_contact_email.downcase,
          provider_id: provider.uid,
          given_name: provider.secondary_technical_contact_given_name,
          family_name: provider.secondary_technical_contact_family_name,
          roles: Array.wrap(contact.roles) << "secondary_technical_contact")
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
