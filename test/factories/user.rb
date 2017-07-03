# spec/factories/todos.rb
FactoryGirl.define do
  factory :user do
    name { Faker::StarWars.character   }
    symbol { Faker::StarWars.character   }
    uid { Faker::Number.between(1, 100) }
    email {Faker::Internet.email}
    role "datacentre_admin"
    jwt {Faker::Code.asin + Faker::Code.isbn}
    orcid {Faker::Code.asin + Faker::Code.isbn}
  end
end
