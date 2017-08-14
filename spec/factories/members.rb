FactoryGirl.define do
  factory :member do
    contact_email { Faker::Internet.email }
    uid { Faker::Code.unique.asin }
    name "My member"
    country_code { Faker::Address.country_code }
  end
end
