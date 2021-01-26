# frozen_string_literal: true

class RoleSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :roles
  set_id :uid

  attributes :role_name,
             :created,
             :updated,
             :deleted

  belongs_to :contact, record_type: :contacts

  attribute :created, &:created_at
  attribute :updated, &:updated_at
  attribute :deleted, &:deleted_at
end
