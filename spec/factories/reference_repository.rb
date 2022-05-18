# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :reference_repository do
    client_id { nil }
    re3doi { nil }
  end
end
