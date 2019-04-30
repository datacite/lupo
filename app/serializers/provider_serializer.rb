class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :providers
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :name, :symbol, :website, :contact_name, :contact_email, :phone, :description, :region, :country, :logo_url, :organization_type, :focus_area, :is_active, :has_password, :joined, :twitter_handle, :billing_information, :ror_id, :created, :updated

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
    object.billing_information.transform_keys!{ |key| key.to_s.camelcase(:lower) } if object.billing_information.present?
  end

  attribute :twitter_handle, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_billing_information, object) == true } do |object|
    object.twitter_handle
  end
end
