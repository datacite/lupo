class ClientSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :clients
  set_id :uid
  cache_options enabled: true, cache_length: 24.hours
  
  attributes :name, :symbol, :re3data, :year, :contact_name, :contact_email, :description, :domains, :url, :created, :updated

  belongs_to :provider, record_type: :providers
  belongs_to :repository, record_type: :repositories, if: Proc.new { |client| client.repository_id }
  has_many :prefixes, record_type: :prefixes

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end
end
