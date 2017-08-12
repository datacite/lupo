FactoryGirl.define do
  factory :member do
    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    doi_quota_allowed 1
    doi_quota_used 1
    name { Faker::Code.unique.asin }
    title "MyString"
    role_name "ROLE_ALLOCATOR"
    #symbol {Faker::Code.unique.asin}
    country_code { Faker::Address.country_code }
  end
end
