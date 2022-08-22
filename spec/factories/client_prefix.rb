# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :client_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider_prefix, factory: :provider_prefix, strategy: :create
    association :client, factory: :client, strategy: :create
  end
end
