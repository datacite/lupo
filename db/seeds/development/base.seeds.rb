require "factory_bot_rails"

fail "Seed tasks can only be used in the development enviroment" if Rails.env.production?
fail "You need to set up a MDS_USERNAME and MDS_PASSWORD" if ENV["MDS_USERNAME"].blank? || ENV["MDS_PASSWORD"].blank?

FactoryBot.create(:provider, symbol: "ADMIN")
provider = FactoryBot.create(:provider, symbol: "DATACITE")
client = FactoryBot.create(:client, provider: provider, symbol: ENV["MDS_USERNAME"], password: ENV["MDS_PASSWORD"])
if Prefix.where(prefix: "10.14454").blank?
  prefix = FactoryBot.create(:prefix, prefix: "10.14454") 
  FactoryBot.create(:client_prefix, client: client, prefix: prefix) 
end
dois = FactoryBot.create_list(:doi, 10, client: client, state: "findable")
FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi)
FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)