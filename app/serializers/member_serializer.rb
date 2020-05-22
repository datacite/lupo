class MemberSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :members
  set_id :uid
  # don't cache members, as they use the provider model
  
  attributes :title, :display_title, :description, :member_type, :organization_type, :focus_area, :region, :country, :year, :logo_url, :email, :website, :joined, :created, :updated

  attribute :title do |object|
    object.name
  end

  attribute :display_title do |object|
    object.display_name
  end

  attribute :email do |object|
    object.group_email
  end

  attribute :country do |object|
    object.country_code
  end
end
