class DoiSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :dois
  set_id :uid
  # don't cache dois, as works are cached using the doi model

  attributes :doi, :prefix, :suffix, :identifiers, :creators, :titles, :publisher, :container, :publication_year, :subjects, :contributors, :dates, :language, :types, :related_identifiers, :sizes, :formats, :version, :rights_list, :descriptions, :geo_locations, :funding_references, :xml, :url, :content_url, :metadata_version, :schema_version, :source, :is_active, :state, :reason, :landing_page, :created, :registered, :updated
  attributes :prefix, :suffix, if: Proc.new { |object, params| params && params[:detail] }

  belongs_to :client, record_type: :clients
  has_many :media, if: Proc.new { |object, params| params && params[:detail] }

  attribute :xml, if: Proc.new { |object, params| params && params[:detail] } do |object|
    object.xml_encoded
  end

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :state do |object|
    object.aasm_state
  end

  attribute :version do |object|
    object.version_info
  end

  attribute :is_active do |object|
    object.is_active.to_s.getbyte(0) == 1 ? true : false
  end

  attribute :landing_page, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_landing_page_results, object) == true } do |object|
    object.landing_page
  end
end
