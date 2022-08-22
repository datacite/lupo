# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :provider do
    system_email { "josiah@example.org" }
    sequence(:symbol, "A") { |n| "TEST#{n}" }
    role_name { "ROLE_ALLOCATOR" }
    globus_uuid { "53d8d984-450d-4b1d-970b-67faff28db1c" }
    name { "My provider" }
    display_name { "My provider" }
    website { Faker::Internet.url }
    country_code { "DE" }
    password_input { "12345" }
    twitter_handle { "@egaTwitterlac" }
    ror_id { "https://ror.org/05njkjr15" }
    billing_information do
      {
        "city": "barcelona",
        "state": "cataluyna",
        "department": "sales",
        "country": "CN",
        "organization": "testing org",
        "address": Faker::Address.street_address,
        "postCode": "10777",
      }
    end
    technical_contact do
      {
        "email": "kristian@example.com",
        "given_name": "Kristian",
        "family_name": "Garza",
      }
    end
    secondary_technical_contact do
      {
        "email": "kristian@example.com",
        "given_name": "Kristian",
        "family_name": "Garza",
      }
    end
    billing_contact do
      {
        "email": "trisha@example.com",
        "given_name": "Trisha",
        "family_name": "Cruse",
      }
    end
    secondary_billing_contact do
      {
        "email": "trisha@example.com",
        "given_name": "Trisha",
        "family_name": "Cruse",
      }
    end
    service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    secondary_service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    voting_contact do
      {
        "email": "robin@example.com",
        "given_name": "Robin",
        "family_name": "Dasler",
      }
    end
    is_active { true }

    initialize_with { Provider.where(symbol: symbol).first_or_initialize }
  end
end
