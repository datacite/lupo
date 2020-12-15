# frozen_string_literal: true

class RepositorySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :repositories
  set_id :uid

  attributes :name,
             :symbol,
             :re3data,
             :opendoar,
             :year,
             :system_email,
             :globus_uuid,
             :alternate_name,
             :description,
             :client_type,
             :repository_type,
             :language,
             :certificate,
             :domains,
             :issn,
             :url,
             :salesforce_id,
             :created,
             :updated

  belongs_to :provider, record_type: :providers
  has_many :prefixes, record_type: :prefixes

  attribute :re3data do |object|
    "https://doi.org/#{object.re3data_id}" if object.re3data_id.present?
  end

  attribute :opendoar do |object|
    if object.opendoar_id.present?
      "https://v2.sherpa.ac.uk/id/repository/#{object.opendoar_id}"
    end
  end

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1
  end

  attribute :has_password,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_contact_information,
                    object,
                  ) ==
                    true
              } do |object|
    object.password.present?
  end

  attribute :system_email,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_contact_information,
                    object,
                  ) ==
                    true
              } do |object|
    object.system_email
  end

  attribute :service_contact,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_contact_information,
                    object,
                  ) ==
                    true
              } do |object|
    if object.service_contact.present?
      object.service_contact.transform_keys! do |key|
        key.to_s.camelcase(:lower)
      end
    else
      {}
    end
  end

  attribute :globus_uuid,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(
                    :read_billing_information,
                    object,
                  ) ==
                    true
              },
            &:globus_uuid

  attribute :salesforce_id,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(:read_salesforce_id, object) ==
                    true
              },
            &:salesforce_id
end
