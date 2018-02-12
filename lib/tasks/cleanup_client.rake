# namespace :cleanup_client do
#   desc 'Deletes all the DOIS of a Clients that is moving away from DataCite'
#   task :cleanup => :environment do
#     client = Client.find(symbol)
#     client.dois.each { |doi|  }
#   end
# end