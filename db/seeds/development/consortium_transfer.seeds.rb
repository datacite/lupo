# frozen_string_literal: true

require "factory_bot_rails"

if Rails.env.production?
  fail "Seed tasks can only be used in the development enviroment"
end

after "development:base" do
  if Prefix.where(uid: "10.14459").blank?
    FactoryBot.create(:prefix, uid: "10.14459")
  end
  provider =
    Provider.where(symbol: "QUECHUA").first ||
    FactoryBot.create(:provider, symbol: "QUECHUA")
  client =
    Client.where(symbol: "QUECHUA.TEXT").first ||
    FactoryBot.create(
      :client,
      provider: provider,
      symbol: "QUECHUA.TEXT",
      password: ENV["MDS_PASSWORD"],
    )
  dois = FactoryBot.create_list(:doi, 10, client: client, state: "findable")
  FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi)
  FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)
end
