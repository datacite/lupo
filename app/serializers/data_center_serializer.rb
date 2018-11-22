class DataCenterSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "data-centers"
  set_id :uid
  # don't cache data-centers, as they use the client model
  
  attributes :title, :other_names, :prefixes, :member_id, :year, :created, :updated

  belongs_to :provider, key: :member, record_type: :members, serializer: :Member

  attribute :title do |object|
    object.name
  end

  attribute :member_id do |object|
    object.provider_id
  end

  attribute :other_names do |object|
    []
  end

  attribute :prefixes do |object|
    []
  end
end
