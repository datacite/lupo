class RepositorySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :repositories
  set_id :uid
  
  attributes :name, :symbol, :re3data, :opendoar, :year, :contact_name, :contact_email, :alternate_name, :description, :client_type, :language, :certificate, :domains, :url, :created, :updated

  belongs_to :provider, record_type: :providers
  has_many :prefixes, record_type: :prefixes

  attribute :re3data do |object|
    "https://doi.org/#{object.re3data_id}" if object.re3data_id.present?
  end

  attribute :opendoar do |object|
    "https://v2.sherpa.ac.uk/id/repository/#{object.opendoar_id}" if object.opendoar_id.present?
  end

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end
end
