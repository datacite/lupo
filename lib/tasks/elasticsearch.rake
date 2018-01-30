namespace :elasticsearch do
  desc 'Push to ElasticSearch Ingestion'
  task :ingest => :environment do
    url = "#{ENV["LEVRIERO_URL"]}/providers"
    data = Provider.all
    data.each do |provider|    
      params = { "data" => { "type" => "providers", "attributes" => provider.attributes } }
      params["data"]["attributes"]["updated"]= params["data"]["attributes"]["updated"].to_s
      params["data"]["attributes"]["created"]= params["data"]["attributes"]["created"].to_s
      ElasticsearchJob.perform_later(url, params)
    end

    url = "#{ENV["LEVRIERO_URL"]}/clients"
    data = Client.all

    data.each do |client|      
    
      params = { "data" => { "type" => "providers", "attributes" => client.attributes } }
      params["data"]["attributes"]["contact-email"]= params["data"]["attributes"]["contact_email"]
      params["data"]["attributes"]["contact-name"]= params["data"]["attributes"]["contact_name"]
      params["data"]["attributes"]["updated"]= params["data"]["attributes"]["updated"].to_s
      params["data"]["attributes"]["created"]= params["data"]["attributes"]["created"].to_s
      ElasticsearchJob.perform_later(url, params)
    end
  end
end