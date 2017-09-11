require 'faker'
FactoryGirl.define do
  factory :provider do
    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    uid { Faker::Code.unique.asin }
    name "My provider"
    country_code { Faker::Address.country_code }
  end
end
