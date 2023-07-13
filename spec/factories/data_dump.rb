# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :data_dump do
    transient do
      year { Faker::Number.within(2010..2021).to_s }
    end

    uid { Faker::Internet.password(8).downcase }
    scope { "metadata" }
    description { "Test Metadata Data Dump Factory creation"}
    start_date { "#{year}-01-01" }
    end_date { "#{year}-12-31" }
    records { Faker::Number.within(5_000_000..50_000_000) }
    checksum { Faker::Crypto.sha256 }
    created_at { Faker::Time.backward(1, :morning) }
    updated_at { Faker::Time.backward(1, :evening) }
    aasm_state { :complete }
  end

  factory :data_dump_incomplete do
    transient do
      year { Faker::Number.within(2010..2021).to_s }
    end

    uid { Faker::Internet.password(8).downcase }
    scope { "metadata" }
    description { "Test Metadata Data Dump Factory creation - incomplete"}
    start_date { "#{year}-01-01" }
    end_date { "#{year}-12-31" }
    created_at { Faker::Time.backward(1, :morning) }
    updated_at { Faker::Time.backward(1, :evening) }
    aasm_state { :generating }
  end
end