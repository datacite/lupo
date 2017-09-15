FactoryGirl.define do
  factory :dataset do
    association :datacentre, factory: :client, strategy: :create

    created {Faker::Time.backward(14, :evening)}
    doi { "10.4122/" + Faker::Internet.password(8) }
    updated {Faker::Time.backward(5, :evening)}
    version 1
    url {Faker::Internet.url }
    is_active 1
    minted {Faker::Time.backward(15, :evening)}
    client_id  { datacentre.symbol }

  end
end
