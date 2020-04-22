require "factory_bot_rails"

fail "Seed tasks can only be used in the development enviroment" if Rails.env.production?

after "development:base" do

## ranks
# Lieutenant of Supplies
# Master of Ships
# Commander of the Law
# General of Warlords
# Supreme Master
# Supreme General
# Wing Commander
# Lawbringer
# Lord General
# Paladin

  provider = Provider.where(symbol: "GENERAL").first || FactoryBot.create(:provider, symbol: "GENERAL")
  client = Client.where(symbol: "PALADIN").first || FactoryBot.create(:client, provider: provider, symbol: "PALADIN", password: ENV["MDS_PASSWORD"]) 
  if Prefix.where(uid: "10.14456").blank?
    prefix = FactoryBot.create(:prefix, uid: "10.14456") 
    # FactoryBot.create(:client_prefix, client_id: client.id, prefix_id: prefix.id) 
  end
  dois = FactoryBot.create_list(:doi, 10, client: client, state: "findable")
  FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi)
  FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)
end



