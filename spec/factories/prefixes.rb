# spec/factories/todos.rb
FactoryGirl.define do
  factory :prefix do
    prefix {  Faker::Code.unique.isbn  }
    version { Faker::Number.between(1, 10) }
    created {Faker::Time.backward(14, :evening)}

    association :allocator, factory: :provider, strategy: :create
  end
end
