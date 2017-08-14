FactoryGirl.define do
  factory :dataset do
    created {Faker::Time.backward(14, :evening)}
    doi {Faker::Bitcoin.unique.address}
    is_active ""
    updated {Faker::Time.backward(5, :evening)}
    version 1
    minted {Faker::Time.backward(15, :evening)}

    association :datacenter, factory: :datacenter, strategy: :build
  end
end
