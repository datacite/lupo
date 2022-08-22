# frozen_string_literal: true

require "faker"

FactoryBot.define do

  factory :metadata do
    doi
  end

  factory :media do
    doi

    url { Faker::Internet.url }
    media_type { "application/json" }
  end

  factory :prefix do
    sequence(:uid) { |n| "10.508#{n}" }
  end

  factory :provider_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider, factory: :provider, strategy: :create
  end

  factory :activity do
    association :auditable, factory: :doi, strategy: :create
  end

end
