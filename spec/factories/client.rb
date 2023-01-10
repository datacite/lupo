# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    provider

    system_email { "josiah@example.org" }
    service_contact do
      {
        "email": "martin@example.com",
        "given_name": "Martin",
        "family_name": "Fenner",
      }
    end
    globus_uuid { "bc7d0274-3472-4a79-b631-e4c7baccc667" }
    sequence(:symbol) { |n| provider.symbol + ".TEST#{n}" }
    name { "My data center" }
    role_name { "ROLE_DATACENTRE" }
    password_input { "12345" }
    is_active { true }
    subjects do
      [
        {
          classificationCode: "1001",
          schemeUri: "http://example.com/schemeUri",
          subject: "Example Subject",
          subjectScheme: "Example Subject Scheme (ESS)",
        },
      ]
    end

    factory :client_with_fos do
      subjects do
        [
          {
            classificationCode: "1001",
            schemeUri: "http://example.com/schemeUri",
            subject: "Example Subject",
            subjectScheme: "Fields of Science and Technology (FOS)"
          },
        ]
      end
    end

    initialize_with { Client.where(symbol: symbol).first_or_initialize }
  end
end
