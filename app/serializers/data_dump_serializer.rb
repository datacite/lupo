# frozen_string_literal: true

class DataDumpSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type "data-dump"
  set_id :uid

  attributes :description,
             :scope,
             :start_date,
             :end_date,
             :records,
             :checksum,
             :download_link,
             :created_at,
             :updated_at

  attribute :download_link do |object|
    "https://example.com/#{object.file_path}"
  end
end