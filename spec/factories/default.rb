require 'faker'

FactoryBot.define do
  factory :client do
    provider

    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    symbol { provider.symbol + ".TEST" }
    name "My data center"
    role_name "ROLE_DATACENTRE"

    initialize_with { Client.where(symbol: symbol).first_or_initialize }
  end

  factory :client_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider_prefix, factory: :provider_prefix, strategy: :create
    association :client, factory: :client, strategy: :create
  end

  factory :doi do
    client

    created {Faker::Time.backward(14, :evening)}
    doi { ("10.4122/" + Faker::Internet.password(8)).downcase }
    updated {Faker::Time.backward(5, :evening)}
    version 1
    url {Faker::Internet.url }
    is_active 1
    minted {Faker::Time.backward(15, :evening)}

    initialize_with { Doi.where(doi: doi).first_or_initialize }
  end

  factory :metadata do
    association :doi

    version 1
    metadata_version 4
    is_converted_by_mds ""
    namespace "MyString"
    xml  'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48cmVzb3VyY2UgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM9Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IiB4c2k6c2NoZW1hTG9jYXRpb249Imh0dHA6Ly9kYXRhY2l0ZS5vcmcvc2NoZW1hL2tlcm5lbC00IGh0dHA6Ly9zY2hlbWEuZGF0YWNpdGUub3JnL21ldGEva2VybmVsLTQvbWV0YWRhdGEueHNkIj48aWRlbnRpZmllciBpZGVudGlmaWVyVHlwZT0iRE9JIj4xMC4yNTQ5OS94dWRhMnB6cmFocm9lcXBlZnZucTV6dDZkYzwvaWRlbnRpZmllcj48Y3JlYXRvcnM+PGNyZWF0b3I+PGNyZWF0b3JOYW1lPklhbiBQYXJyeTwvY3JlYXRvck5hbWU+PG5hbWVJZGVudGlmaWVyIHNjaGVtZVVSST0iaHR0cDovL29yY2lkLm9yZy8iIG5hbWVJZGVudGlmaWVyU2NoZW1lPSJPUkNJRCI+MDAwMC0wMDAxLTYyMDItNTEzWDwvbmFtZUlkZW50aWZpZXI+PC9jcmVhdG9yPjwvY3JlYXRvcnM+PHRpdGxlcz48dGl0bGU+U3VibWl0dGVkIGNoZW1pY2FsIGRhdGEgZm9yIEluQ2hJS2V5PVlBUFFCWFFZTEpSWFNBLVVIRkZGQU9ZU0EtTjwvdGl0bGU+PC90aXRsZXM+PHB1Ymxpc2hlcj5Sb3lhbCBTb2NpZXR5IG9mIENoZW1pc3RyeTwvcHVibGlzaGVyPjxwdWJsaWNhdGlvblllYXI+MjAxNzwvcHVibGljYXRpb25ZZWFyPjxyZXNvdXJjZVR5cGUgcmVzb3VyY2VUeXBlR2VuZXJhbD0iRGF0YXNldCI+U3Vic3RhbmNlPC9yZXNvdXJjZVR5cGU+PHJpZ2h0c0xpc3Q+PHJpZ2h0cyByaWdodHNVUkk9Imh0dHBzOi8vY3JlYXRpdmVjb21tb25zLm9yZy9zaGFyZS15b3VyLXdvcmsvcHVibGljLWRvbWFpbi9jYzAvIj5ObyBSaWdodHMgUmVzZXJ2ZWQ8L3JpZ2h0cz48L3JpZ2h0c0xpc3Q+PC9yZXNvdXJjZT4='
    dataset { doi.doi }
  end

  factory :media do
    association :doi, factory: :doi, strategy: :create

    version 1
    url {Faker::Internet.url }
    media_type "MyString"
    doi  { doi.doi }
    dataset  { doi.doi }
  end

  factory :prefix do
    prefix {  "10."+Faker::Number.number(4)  }
  end

  factory :provider do
    contact_email { Faker::Internet.email }
    contact_name { Faker::Name.name }
    symbol "TEST"
    name "My provider"
    country_code { Faker::Address.country_code }

    initialize_with { Provider.where(symbol: symbol).first_or_initialize }
  end

  factory :provider_prefix do
    association :prefix, factory: :prefix, strategy: :create
    association :provider, factory: :provider, strategy: :create
  end
end
