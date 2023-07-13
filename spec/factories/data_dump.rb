# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :data_dump do
    uid { Faker::Internet.password(8).downcase }
    scope { "metadata" }
    description { "Test Metadata Data Dump Factory creation"}
    records { 12345 }
    checksum { Faker::Crypto.sha256}
    created_at { Faker::Time.backward(1, :morning) }
    updated_at { Faker::Time.backward(1, :evening) }
    aasm_state { :complete }
  end
  factory :data_dump_incomplete do
    uid { Faker::Internet.password(8).downcase }
    scope { "metadata" }
    description { "Test Metadata Data Dump Factory creation - incomplete" }
    created_at { Faker::Time.backward(2, :morning) }
  end
end