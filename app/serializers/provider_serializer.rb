class ProviderSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :providers
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours

  attributes :name, :symbol, :website, :contact_name, :contact_email, :phone, :description, :region, :country, :logo_url, :organization_type, :focus_area, :is_active, :has_password, :joined, :twitter_handle, :ror_id, :created, :updated

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
end
