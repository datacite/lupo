FactoryGirl.define do
  factory :metadata do
    created {Faker::Time.backward(14, :evening)}
    version 1
    metadata_version 1
    url {Faker::Internet.url }
    is_converted_by_mds ""
    namespace "MyString"
    xml {Faker::Lorem.paragraphs(9, true)}
    dataset_id  { dataset.uid }

    association :dataset, factory: :dataset, strategy: :create
  end
end
