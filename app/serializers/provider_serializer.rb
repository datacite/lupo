class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :providers
  set_id :uid
  # cache_options enabled: true, cache_length: 24.hours ### we cannot filter if we cache

  attributes :name, :display_name, :symbol, :website, :system_email, :group_email, :description, :region, :country, :logo_url, :member_type, :organization_type, :focus_area, :consortium_lead, :is_active, :has_password, :joined, :twitter_handle, :billing_information, :ror_id, :technical_contact, :secondary_technical_contact, :billing_contact, :secondary_billing_contact, :service_contact, :secondary_service_contact, :voting_contact, :created, :updated

  has_many :clients, record_type: :clients
  has_many :prefixes, record_type: :prefixes

  attribute :country do |object|
    object.country_code
  end

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end

  attribute :billing_information, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_billing_information, object) == true } do |object|
    object.billing_information.present? ? object.billing_information.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :twitter_handle, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_billing_information, object) == true } do |object|
    object.twitter_handle
  end

  # Convert all contacts json models back to json style camelCase
  attribute :technical_contact do |object|
    object.technical_contact.present? ? object.technical_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :secondary_technical_contact do |object|
    object.secondary_technical_contact.present? ? object.secondary_technical_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :billing_contact do |object|
    object.billing_contact.present? ? object.billing_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :secondary_billing_contact do |object|
    object.secondary_billing_contact.present? ? object.secondary_billing_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :service_contact do |object|
    object.service_contact.present? ? object.service_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :secondary_service_contact do |object|
    object.secondary_service_contact.present? ? object.secondary_service_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end

  attribute :voting_contact do |object|
    object.voting_contact.present? ? object.voting_contact.transform_keys!{ |key| key.to_s.camelcase(:lower) } : {}
  end
end
