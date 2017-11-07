class WorkSerializer < ActiveModel::Serializer
  include Bolognese::Utils
  include Bolognese::DoiUtils

  cache key: 'work'
  type 'works'
  attributes :doi, :url, :author, :title, :container_title, :description, :resource_type_subtype, :data_center_id, :member_id, :resource_type_id, :version, :license, :schema_version, :results, :related_identifiers, :published, :registered, :updated, :media, :xml

  belongs_to :data_center, serializer: DataCenterSerializer
  belongs_to :member, serializer: MemberSerializer
  belongs_to :resource_type, serializer: ResourceTypeSerializer

  def media
    object.media.present? ? object.media.map { |m| { media_type: m.split(":", 2).first, url: m.split(":", 2).last }} : nil
  end

  def author
    Array.wrap(object.author).map do |a|
      literal = a.fetch("familyName", nil).present? || a.fetch("givenName", nil).present? ? nil : a.fetch("name", nil)

      { "literal" => literal,
        "given" => a.fetch("givenName", nil),
        "family" => a.fetch("familyName", nil),
        "orcid" => a.fetch("id", nil) }.compact
    end
  end

  def doi
    object.doi.downcase
  end

  def title
    t = parse_attributes(object.title, content: "text", first: true)
    t.truncate(255) if t.present?
  end

  def container_title
    object.container_title || object.publisher
  end

  def description
    parse_attributes(object.description, content: "text", first: true)
  end

  def license
    parse_attributes(object.license, content: "id", first: true)
  end

  def resource_type_id
    object.resource_type_general
  end

  def resource_type_subtype
    object.additional_type
  end

  def data_center_id
    object.client_id.downcase
  end

  def member_id
    object.provider_id.downcase
  end

  def updated
    object.updated_at
  end

  def created
    date_created
  end

  def published
    object.date_published
  end

  def registered
    object.date_registered
  end
end
