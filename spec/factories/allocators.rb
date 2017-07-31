FactoryGirl.define do
  factory :allocator do
    comments { Faker::StarWars.character  }
    contact_email { Faker::Internet.email }
    contact_name {Faker::Name.name }
    created {Faker::Time.backward(14, :evening)}
    doi_quota_allowed 1
    doi_quota_used 1
    is_active ""
    name {Faker::StarWars.droid}
    password "MyString"
    role_name "MyString"
    symbol {Faker::Code.unique.asin}
    updated {Faker::Time.backward(5, :evening)}
    version 1
    website { Faker::Internet.url }
    description { Faker::Lorem.paragraph(sentence_count = 1, supplemental = false, random_sentences_to_add = 1) }
    member_type {Faker::StarWars.droid}
    year { Faker::Number.number(4) }
    image { Faker::Internet.url }
    region { Faker::Address.country }
    country_code { Faker::Address.country_code }
    logo { Faker::Internet.url }
    experiments "MyString"
  end
end
