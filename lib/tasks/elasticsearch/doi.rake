namespace :elasticsearch do
  namespace :doi do
    desc 'Import all dois'
    task :import => :environment do
      Doi.__elasticsearch__.create_index!
      Doi.import
    end

    desc "Create index for dois"
    task :create_index => :environment do
      Doi.__elasticsearch__.create_index!
    end

    desc "Delete index for dois"
    task :delete_index => :environment do
      Doi.__elasticsearch__.delete_index!
    end

    desc "Refresh index for dois"
    task :refresh_index => :environment do
      Doi.__elasticsearch__.refresh_index!
    end
  end
end