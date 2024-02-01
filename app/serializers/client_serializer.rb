# frozen_string_literal: true

class ClientSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :clients
  set_id :uid

  attributes :name,
             :symbol,
             :year,
             :contact_email,
             :globus_uuid,
             :alternate_name,
             :description,
             :language,
             :client_type,
             :domains,
             :re3data,
             :opendoar,
             :issn,
             :url,
             :salesforce_id,
             :created,
             :updated
  belongs_to :provider, record_type: :providers
  belongs_to :consortium,
             record_type: :providers,
             serializer: ProviderSerializer,
             if: Proc.new { |provider| provider.consortium_id }
  has_many :prefixes, record_type: :prefixes

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

  attribute :contact_email,
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

  attribute :salesforce_id,
            if:
              Proc.new { |object, params|
                params[:current_ability] &&
                  params[:current_ability].can?(:read_salesforce_id, object) ==
                    true
              },
            &:salesforce_id

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

  attribute :re3data do |object|
    "https://doi.org/#{object.re3data_id}" if object.re3data_id.present?
  end

  attribute :opendoar do |object|
    if object.opendoar_id.present?
      "https://v2.sherpa.ac.uk/id/repository/#{object.opendoar_id}"
    end
  end
end
