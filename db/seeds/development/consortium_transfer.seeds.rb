require "factory_bot_rails"

fail "Seed tasks can only be used in the development enviroment" if Rails.env.production?

after "development:base" do

  provider = Provider.where(symbol: "QUECHUA").first || FactoryBot.create(:provider, symbol: "QUECHUA")
  client = Client.where(symbol: "QUECHUA.TEXT").first || FactoryBot.create(:client, provider: provider, symbol: "QUECHUA.TEXT", password: ENV["MDS_PASSWORD"]) 
  if Prefix.where(uid: "10.14459").blank?
    prefix = FactoryBot.create(:prefix, uid: "10.14459")
    FactoryBot.create(:provider_prefix, provider_id: provider.symbol, prefix_id: prefix.uid) 
    FactoryBot.create(:client_prefix, client_id: client.symbol, prefix_id: prefix.uid)
  end
  dois = FactoryBot.create_list(:doi, 10, client: client, state: "findable")
  FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi)
  FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)
end