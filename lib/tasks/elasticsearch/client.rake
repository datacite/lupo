namespace :elasticsearch do
  namespace :client do
    desc 'Import all clients'
    task :import => :environment do
      Client.import
    end

    desc "Create index for clients"
    task :create_index => :environment do
      Client.__elasticsearch__.create_index!
    end

    desc "Delete index for clients"
    task :delete_index => :environment do
      Client.__elasticsearch__.delete_index!
    end

    desc "Refresh index for clients"
    task :refresh_index => :environment do
      Client.__elasticsearch__.refresh_index!
    end
  end
end