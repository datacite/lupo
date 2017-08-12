FactoryGirl.define do
  factory :datacenter do
    contact_email { Faker::Internet.email }
    contact_name { "ddsdsds" }
    doi_quota_allowed 1
    doi_quota_used 1
    name "MyString"
    role_name "ROLE_DATACENTRE"
    symbol { Faker::Code.asin + Faker::Code.isbn }

    association :member, factory: :member, strategy: :create
  end
end
