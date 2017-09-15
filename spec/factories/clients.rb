FactoryGirl.define do
  factory :client do
    association :allocator, factory: :provider, strategy: :create

    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    uid { allocator.uid + "." + Faker::Code.asin + Faker::Code.isbn }
    name "My data center"
    role_name "ROLE_DATACENTRE"
    provider_id  { allocator.symbol }


  end
end
