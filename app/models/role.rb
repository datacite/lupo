# frozen_string_literal: true

class Role < ApplicationRecord
  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  belongs_to :contact, touch: true

  before_create :set_uid

  ROLES = %w[voting_contact billing_contact secondary_billing_contact service_contact secondary_service_contact technical_contact secondary_technical_contact]

  validates_inclusion_of :role_name,
                         in: ROLES,
                         message: "Role %s is not included in the list of possible roles"
  validates_presence_of :contact

  # use different index for testing
  if Rails.env.test?
    index_name "roles-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "roles-#{ENV['ES_PREFIX']}"
  else
    index_name "roles"
  end

  mapping dynamic: "false" do
    indexes :id, type: :keyword
    indexes :uid, type: :keyword
    indexes :contact_id, type: :keyword
    indexes :role_name, type: :keyword
    indexes :created_at, type: :date
    indexes :updated_at, type: :date
    indexes :deleted_at, type: :date
  end

  def as_indexed_json(options = {})
    {
      "id" => uid,
      "uid" => uid,
      "contact_id" => contact_id,
      "role_name" => role_name,
      "created_at" => created_at.try(:iso8601),
      "updated_at" => updated_at.try(:iso8601),
      "deleted_at" => deleted_at.try(:iso8601),
    }
  end

  def contact_id
    contact.uid
  end

  def contact_id=(value)
    r = Contact.where(uid: value).first
    return nil if r.blank?

    write_attribute(:contact_id, r.id)
  end

  private
    # uuid for public id
    def set_uid
      self.uid = SecureRandom.uuid if self.uid.blank?
    end
end
