# spec/factories/todos.rb
FactoryGirl.define do
  factory :datacenter do
    name { Faker::Team.name }
    allocator { Faker::Team.name }
  end
end
