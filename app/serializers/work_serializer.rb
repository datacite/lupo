# frozen_string_literal: true

class WorkSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :dash
  set_type :works
  set_id :identifier
  # cache_options enabled: true, cache_length: 24.hours
  cache_options store: Rails.cache, namespace: 'jsonapi-serializer', expires_in: 24.hours

  attributes :doi,
             :identifier,
             :url,
             :author,
             :title,
             :container_title,
             :description,
             :resource_type_subtype,
             :data_center_id,
             :member_id,
             :resource_type_id,
             :version,
             :license,
             :schema_version,
             :results,
             :related_identifiers,
             :related_items,
             :citation_count,
             :citations_over_time,
             :view_count,
             :views_over_time,
             :download_count,
             :downloads_over_time,
             :published,
             :registered,
             :checked,
             :updated,
             :media,
             :xml

  belongs_to :client,
             key: "data-center",
             record_type: "data-centers",
             serializer: :DataCenter
  belongs_to :provider, key: :member, record_type: :members, serializer: :Member
  belongs_to :resource_type,
             record_type: "resource-types", serializer: :ResourceType

  attribute :author do |object|
    Array.wrap(object.creators).map do |c|
      if c["givenName"].present? || c["familyName"].present?
        { "given" => c["givenName"], "family" => c["familyName"] }.compact
      else
        { "literal" => c["name"] }.presence
      end
    end
  end

  attribute :doi do |object|
    object.doi.downcase
  end

  attribute :title do |object|
    Array.wrap(object.titles).first.to_h.fetch("title", nil)
  end

  attribute :description do |object|
    Array.wrap(object.descriptions).first.to_h.fetch("description", nil)
  end

  attribute :container_title do |object|
    if object.publisher.respond_to?(:to_hash)
      object.publisher["name"]
    elsif object.publisher.respond_to?(:to_str)
      object.publisher
    end
  end

  attribute :resource_type_subtype do |object|
    object.types.to_h.fetch("resourceType", nil)
  end

  attribute :resource_type_id do |object|
    rt = object.types.to_h.fetch("resourceTypeGeneral", nil)
    rt&.downcase&.dasherize
  end

  attribute :data_center_id, &:client_id

  attribute :member_id, &:provider_id

  attribute :version, &:version_info

  attribute :schema_version do |object|
    object.schema_version.to_s.split("-", 2).last.presence
  end

  attribute :license do |object|
    Array.wrap(object.rights_list).first.to_h.fetch("rightsUri", nil)
  end

  attribute :results do |_object|
    []
  end

  attribute :related_identifiers do |_object|
    []
  end

  attribute :related_items do |_object|
    []
  end

  attribute :published do |object|
    object.publication_year.to_s.presence
  end

  attribute :xml do |object|
    Base64.strict_encode64(object.xml) if object.xml.present?
  end

  attribute :checked do |_object|
    nil
  end
end
