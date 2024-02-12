# frozen_string_literal: true

class OldObjectSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :dash
  set_type :objects

  attributes :subtype,
             :name,
             :author,
             :periodical,
             :volume_number,
             :issue_number,
             :pagination,
             :publisher,
             :issn,
             :version,
             :date_published

  attribute :subtype do |object|
    object["@type"]
  end
end
