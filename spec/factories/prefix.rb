# spec/factories/todos.rb
FactoryGirl.define do
  factory :prefix do
    prefix {  Faker::Name.first_name  }
    version { Faker::Number.between(1, 10) }
  end
end
