# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    provider

    domains { "*" }
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

    factory :client_with_fos do
      repository_type { "disciplinary" }
      subjects do
        [
          {
            subject: "Physical sciences",
            valueUri: "",
            schemeUri: "http://www.oecd.org/science/inno/38235147.pdf",
            subjectScheme: "Fields of Science and Technology (FOS)",
            classificationCode: "1001",
          },
        ]
      end
    end

    initialize_with { Client.where(symbol: symbol).first_or_initialize }
  end
end
