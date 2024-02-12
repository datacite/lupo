# frozen_string_literal: true

class DataCenterSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :dash
  set_type "data-centers"
  set_id :uid
  # don't cache data-centers, as they use the client model

  attributes :title,
             :other_names,
             :prefixes,
             :member_id,
             :year,
             :created,
             :updated

  belongs_to :provider, key: :member, record_type: :members, serializer: :Member

  attribute :title, &:name

  attribute :member_id, &:provider_id

  attribute :other_names do |_object|
    []
  end

  attribute :prefixes do |_object|
    []
  end
end
