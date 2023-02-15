# frozen_string_literal: true

require "factory_bot_rails"

if Rails.env.production?
  fail "Seed tasks can only be used in the development enviroment"
end
if ENV["MDS_USERNAME"].blank? || ENV["MDS_PASSWORD"].blank?
  fail "You need to set up a MDS_USERNAME and MDS_PASSWORD"
end

if Provider.where(symbol: "ADMIN").blank?
  FactoryBot.create(:provider, symbol: "ADMIN")
end
# Need available prefixes for repository creation.
if Prefix.where(uid: "10.14454").blank?
  FactoryBot.create(:prefix, uid: "10.14454")
end
provider =
  Provider.where(symbol: "DATACITE").first ||
  FactoryBot.create(:provider, symbol: "DATACITE")
# No need anymore to call FactoryBot.create to establish provider/client prefix relationships.
# That is done in client creation.
client =
  Client.where(symbol: "DATACITE.TEST").first ||
  FactoryBot.create(
    :client_with_fos,
    provider: provider,
    symbol: ENV["MDS_USERNAME"],
    password_input: ENV["MDS_PASSWORD"],
  )
if Prefix.where(uid: "10.14454").blank?
  prefix = FactoryBot.create(:prefix, uid: "10.14454")
  ### This creates both the client_prefix and the provider association
  FactoryBot.create(
    :client_prefix,
    client_id: client.symbol, prefix_id: prefix.uid,
  )
end
dois = FactoryBot.create_list(:doi, 10, client: client, state: "findable")
FactoryBot.create_list(:event_for_datacite_related, 3, obj_id: dois.first.doi)
FactoryBot.create_list(:event_for_datacite_usage, 2, obj_id: dois.first.doi)
