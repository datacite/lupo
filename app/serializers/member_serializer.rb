class MemberSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :members
  set_id :uid
  # cache_options enabled: true, cache_length: 24.hours
  attributes :title, :description, :member_type, :institution_type, :region, :country, :year, :logo_url, :email, :website, :phone, :joined, :created, :updated

  attribute :title do |object|
    object.name
  end

  attribute :email do |object|
    object.contact_email
  end

  attribute :country do |object|
    object.country_code
  end
end
