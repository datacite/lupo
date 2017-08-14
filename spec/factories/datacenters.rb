FactoryGirl.define do
  factory :datacenter do
    contact_email { Faker::Internet.email }
    uid { Faker::Code.asin + Faker::Code.isbn }
    name "My data center"
    role_name "ROLE_DATACENTRE"

    association :member, factory: :member, strategy: :create
  end
end
