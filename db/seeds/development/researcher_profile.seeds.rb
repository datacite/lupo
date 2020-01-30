require "factory_bot_rails"

after :base do
  client = Client.all.first
  dois = FactoryBot.create_list(:doi,70, client: client, state: "findable")

  FactoryBot.create_list(:event_for_datacite_related, 34, obj_id: dois.first.doi) 
  FactoryBot.create_list(:event_for_datacite_usage, 32, obj_id: dois.first.doi)
  FactoryBot.create_list(:event_for_datacite_orcid_auto_update, 5, subj_id: dois.first.doi, obj_id: 'http://orcid.org/0000-0003-2926-8353') 
end