FactoryGirl.define do
  factory :user do
    name { Faker::StarWars.character }
    uid { Faker::Number.between(1, 100) }
    email {Faker::Internet.email}
    role "client_admin"
    jwt {Faker::Code.asin + Faker::Code.isbn}
    orcid {Faker::Code.asin + Faker::Code.isbn}
    provider_id  { ["TIB", "CDL", "GER", "MEX"].sample }
    client_id { ["KIT-IMK", "DATACITE", "NYU", "UNAM"].sample }
  end
end
