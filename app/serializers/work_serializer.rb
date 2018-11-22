class WorkSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :works
  set_id :identifier

  attributes :doi, :identifier, :url, :author, :title, :container_title, :description, :resource_type_subtype, :data_center_id, :member_id, :resource_type_id, :version, :license, :schema_version, :results, :related_identifiers, :published, :registered, :checked, :updated, :media, :xml

  belongs_to :client, key: "data-center", record_type: "data-centers", serializer: :DataCenter
  belongs_to :provider, key: :member, record_type: :members, serializer: :Member
  belongs_to :resource_type, record_type: "resource-types", serializer: :ResourceType

  attribute :author do |object|
    Array.wrap(object.creator).map do |c| 
      if (c["givenName"].present? || c["familyName"].present?)
        { "given" => c["givenName"],
          "family" => c["familyName"] }.compact
      else
        { "literal" => c["name"] }.presence
      end
    end
  end

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :title do |object|
    object.titles.first.to_h.fetch("title", nil)
  end

  attribute :description do |object|
    object.descriptions.first.to_h.fetch("title", nil)
  end

  attribute :container_title do |object|
    object.publisher
  end

  attribute :resource_type_subtype do |object|
    object.types.fetch("resourceType", nil)
  end

  attribute :resource_type_id do |object|
    rt = object.types.fetch("resourceTypeGeneral", nil)
    rt.downcase.dasherize if rt
  end

  attribute :data_center_id do |object|
    object.client_id
  end

  attribute :member_id do |object|
    object.provider_id
  end

  attribute :version do |object|
    object.version_info
  end

  attribute :schema_version do |object|
    object.schema_version.split("-", 2).last
  end

  attribute :license do |object|
    object.rights_list.first.try(:rightsUri)
  end

  attribute :results do |object|
    []
  end

  attribute :related_identifiers do |object|
    []
  end

  attribute :published do |object|
    object.publication_year.to_s
  end

  attribute :xml do |object|
    Base64.strict_encode64(object.xml) if object.xml.present?
  end

  attribute :checked do |object|
    nil
  end
end