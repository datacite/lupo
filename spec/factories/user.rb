# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |_n| "Josiah Carberry#{_n}" }
    provider { "globus" }
    role_id { "user" }
    sequence(:uid) { |n| "0000-0002-1825-000#{n}" }

    factory :admin_user do
      role_id { "staff_admin" }
      uid { "0000-0002-1825-0003" }
    end

    factory :staff_user do
      role_id { "staff_user" }
      uid { "0000-0002-1825-0004" }
    end

    factory :regular_user do
      role_id { "user" }
      uid { "0000-0002-1825-0001" }
    end

    factory :valid_user do
      uid { "0000-0002-7352-517X" }
      orcid_token { ENV["ACCESS_TOKEN"] }
    end

    factory :invalid_user do
      uid { "0000-0002-7352-517X" }
      orcid_token { nil }
    end

    initialize_with do
      User.new(
        User.generate_alb_token(uid: uid, role_id: role_id),
        type: "oidc",
      )
    end
  end
end
