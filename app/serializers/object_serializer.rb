# frozen_string_literal: true

class ObjectSerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :objects

  attributes :subtype,
             :name,
             :author,
             :publisher,
             :periodical,
             :included_in_data_catalog,
             :version,
             :date_published,
             :date_modified,
             :funder,
             :proxy_identifiers,
             :registrant_id

  attribute :subtype do |object|
    object["@type"]
  end
end
