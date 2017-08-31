class WorksSerializer < ActiveModel::Serializer
  cache key: 'works'
  type "works"

  attributes   :doi, :identifier, :xml, :media, :author, :url, :title, :container_title, :description, :resource_type_subtype, :data_center_id, :member_id, :resource_type_id, :data_center, :member, :registration_agency, :resource_type, :license, :version, :results, :related_identifiers, :schema_version, :published, :registered, :updated_at


end
