class DoisSerializer < ActiveModel::Serializer
  cache key: 'dois'
  type "dois"

  attributes   :doi, :identifier, :xml, :media, :author, :url, :title, :container_title, :description, :resource_type_subtype, :client_id, :provider_id, :resource_type_id, :client, :provider, :registration_agency, :resource_type, :license, :version, :results, :related_identifiers, :schema_version, :published, :registered, :updated_at


end
