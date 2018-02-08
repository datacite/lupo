namespace :elasticsearch do
  desc 'Push to ElasticSearch Ingestion'
  task :ingest => :environment do
    Provider.push_to_index
    Client.push_to_index
  end
end