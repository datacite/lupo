FactoryGirl.define do
  factory :media do
    created {Faker::Time.backward(14, :evening)}
    updated {Faker::Time.backward(14, :evening)}
    version 1
    url {Faker::Internet.url }
    media_type "MyString"
    dataset_id  { dataset.uid }

    association :dataset, factory: :dataset, strategy: :create
  end
end
