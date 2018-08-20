class DataCenterSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type "data-centers"
  set_id :uid
  #cache_options enabled: true, cache_length: 24.hours
  
  attributes :title, :other_names, :prefixes, :member_id, :year, :created, :updated

  belongs_to :member, record_type: :members, id_method_name: :provider_id

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
