require "factory_bot_rails"


FactoryBot.create(:provider, symbol: "ADMIN")
provider = FactoryBot.create(:provider, symbol: "DATACITE")
client = FactoryBot.create(:client, provider: provider, symbol: ENV['MDS_USERNAME'], password: ENV['MDS_PASSWORD'])
prefix = FactoryBot.create(:prefix, prefix: "10.14454")
FactoryBot.create(:client_prefix, client: client, prefix: prefix)
dois = FactoryBot.create_list(:doi,10, client: client, state: "findable")

FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi) 
FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)

