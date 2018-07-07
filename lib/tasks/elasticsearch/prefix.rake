namespace :elasticsearch do
  namespace :prefix do
    desc 'Import all prefixes'
    task :import => :environment do
      Prefix.__elasticsearch__.create_index!
      Prefix.import
    end

    desc "Create index for prefixes"
    task :create_index => :environment do
      Prefix.__elasticsearch__.create_index!
    end

    desc "Delete index for prefixes"
    task :delete_index => :environment do
      Prefix.__elasticsearch__.delete_index!
    end

    desc "Refresh index for prefixes"
    task :refresh_index => :environment do
      Prefix.__elasticsearch__.refresh_index!
    end
  end
end