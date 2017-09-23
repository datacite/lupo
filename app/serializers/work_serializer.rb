class WorkSerializer < ActiveModel::Serializer
  #cache key: 'work'
  type 'works'
  attributes :doi, :identifier, :url, :author, :title, :container_title, :description, :resource_type_subtype, :data_center_id, :member_id, :resource_type_id, :version, :license, :schema_version, :results, :related_identifiers, :published, :registered, :updated, :media, :xml

  belongs_to :data_center, serializer: DataCenterSerializer
  belongs_to :member, serializer: MemberSerializer
  belongs_to :resource_type, serializer: ResourceTypeSerializer

  def media
    object.media.present? ? object.media.map { |m| { media_type: m.split(":", 2).first, url: m.split(":", 2).last }} : nil
  end

  def data_center_id
    object.client_id
  end

  def member_id
    object.provider_id
  end

  def updated
    object.updated_at
  end
end
