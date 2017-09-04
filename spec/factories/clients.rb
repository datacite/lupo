FactoryGirl.define do
  factory :client do
    contact_email { Faker::Internet.email }
    uid { Faker::Code.asin + Faker::Code.isbn }
    name "My data center"
    role_name "ROLE_DATACENTRE"
    provider_id  { allocator.uid }

    association :allocator, factory: :provider, strategy: :create
  end
end
