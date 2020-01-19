class ClientSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :clients
  set_id :uid
  
  attributes :name, :symbol, :year, :contact_email, :alternate_name, :description, :language, :client_type, :domains, :re3data, :opendoar, :issn, :url, :salesforce_id, :created, :updated

  belongs_to :provider, record_type: :providers
  belongs_to :consortium, record_type: :providers, serializer: ProviderSerializer, if: Proc.new { |client| client.consortium_id }
  has_many :prefixes, record_type: :prefixes

  attribute :is_active do |object|
    object.is_active.getbyte(0) == 1 ? true : false
  end

  attribute :has_password do |object|
    object.password.present?
  end

  attribute :contact_email do |object|
    object.system_email
  end

  attribute :salesforce_id, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_salesforce_id, object) == true } do |object|
    object.salesforce_id
  end

  attribute :re3data do |object|
    "https://doi.org/#{object.re3data_id}" if object.re3data_id.present?
  end

  attribute :opendoar do |object|
    "https://v2.sherpa.ac.uk/id/repository/#{object.opendoar_id}" if object.opendoar_id.present?
  end
end
