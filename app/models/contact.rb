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

  private
    # uuid for public id
    def set_uid
      self.uid = SecureRandom.uuid if self.uid.blank?
    end
end
