namespace :researcher do
  desc 'Import all researchers'
  task :import => :environment do
    Researcher.__elasticsearch__.create_index!
    Researcher.import
  end

  desc "Create index for researchers"
  task :create_index => :environment do
    Researcher.__elasticsearch__.create_index!
  end

  desc "Delete index for researchers"
  task :delete_index => :environment do
    Researcher.__elasticsearch__.delete_index!
  end

  desc "Refresh index for researchers"
  task :refresh_index => :environment do
    Researcher.__elasticsearch__.refresh_index!
  end
end