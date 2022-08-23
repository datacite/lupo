# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    provider

    uid { SecureRandom.uuid }
    sequence(:email) { |n| "josiah#{n}@example.org" }
    given_name { "Josiah" }
    family_name { "Carberry" }
    role_name { ["voting"] }

    initialize_with { Contact.where(uid: uid).first_or_initialize }
  end
end
