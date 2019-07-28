class ClientSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :clients
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :name, :alternate_name, :symbol, :year, :contact_name, :contact_email, :description, :language, :client_type, :domains, :url, :created, :updated

  belongs_to :provider, record_type: :providers
  has_many :prefixes, record_type: :prefixes

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end
end
