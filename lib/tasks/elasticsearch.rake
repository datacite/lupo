require 'elasticsearch/rails/tasks/import'
require 'elasticsearch'

namespace :elasticsearch_api do
  desc "Create Alias for specific index using ENV['INDEX_NAME'] and ENV['ALIAS']"
  task :alias_index => :environment do
    if ENV['INDEX_NAME'].nil? || ENV['ALIAS'].nil?
      puts "ENV['INDEX_NAME'] ENV['ALIAS'] required"
      exit
    end
  
    client = Elasticsearch::Client.new log: true, host: ENV['ES_HOST']

    client.indices.get_alias(name: ENV['ALIAS']).each do |indice|
      puts "Removing all Aliases first"
      client.indices.delete_alias index: indice.first, name: ENV['ALIAS']
    end if client.indices.exists_alias? name: ENV['ALIAS']

    puts "Assiging new Alias"
    client.indices.put_alias index: ENV['INDEX_NAME'], name: ENV['ALIAS']
  end

  desc "Delete index for specific index using ENV['INDEX_NAME']"
  ### We need this when the model is pointintg to an alias rathe than an index directly
  task :delete_index => :environment do
    if ENV['INDEX_NAME'].nil? 
      puts "ENV['INDEX_NAME'] required"
      exit
    end
  
    client.indices.delete index: ENV['INDEX_NAME']
  end
end

