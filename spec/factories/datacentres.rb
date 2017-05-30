# spec/factories/todos.rb
FactoryGirl.define do
  factory :datacentre do
    name { Faker::StarWars.character  }
    allocator { Faker::StarWars.specie }
    symbol "DATACITE.DATACITE"
  end
end
