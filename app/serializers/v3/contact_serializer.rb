# frozen_string_literal: true

module V3
  class ContactSerializer
    include FastJsonapi::ObjectSerializer
    set_key_transform :camel_lower
    set_type :contacts
    set_id :uid

    attributes :given_name,
              :family_name,
              :name,
              :email,
              :role_name,
              :created,
              :updated,
              :deleted

    belongs_to :provider, record_type: :providers

    attribute :name do |object|
      object.name.present? ? object.name : nil
    end

    attribute :created, &:created_at
    attribute :updated, &:updated_at
    attribute :deleted, &:deleted_at
  end
end
