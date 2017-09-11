FactoryGirl.define do
  factory :client do
    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    uid { Faker::Code.asin + Faker::Code.isbn }
    name "My data center"
    role_name "ROLE_DATACENTRE"
    provider  { allocator }

    association :allocator, factory: :provider, strategy: :create
  end
end
