FactoryGirl.define do
  factory :client do
    contact_email { Faker::Internet.email }
    uid { Faker::Code.asin + Faker::Code.isbn }
    name "My data center"
    role_name "ROLE_DATACENTRE"
    member_id  { allocator.uid }

    association :allocator, factory: :member, strategy: :create
  end
end
