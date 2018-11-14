class MemberSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :members
  set_id :uid
  # don't cache members, as they use the provider model
  
  attributes :title, :description, :member_type, :organization_type, :focus_area, :region, :country, :year, :logo_url, :email, :website, :phone, :joined, :created, :updated

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
