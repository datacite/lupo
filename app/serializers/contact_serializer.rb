# frozen_string_literal: true

class ContactSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :contacts
  set_id :uid

  attributes :given_name,
             :family_name,
             :name,
             :email,
             :role_name,
             :from_salesforce,
             :created,
             :updated,
             :deleted

  belongs_to :provider, record_type: :providers,
      if:
        Proc.new { |object, params|
          object.provider_id = object.provider_id.downcase
        }

  attribute :name do |object|
    object.name.present? ? object.name : nil
  end

  attribute :created, &:created_at
  attribute :updated, &:updated_at
  attribute :deleted, &:deleted_at

  attribute :from_salesforce,
            if:
              Proc.new { |object, params|
                params[:detail] && params[:current_ability] &&
                  params[:current_ability].can?(:read_salesforce_id, object) ==
                    true
              },
            &:from_salesforce
end
