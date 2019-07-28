class PeriodicalSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :periodicals
  set_id :uid

  attributes :name, :symbol, :year, :contact_name, :contact_email, :alternate_name, :description, :client_type, :language, :domains, :issn, :url, :created, :updated

  belongs_to :provider, record_type: :providers
  has_many :prefixes, record_type: :prefixes

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end
end
