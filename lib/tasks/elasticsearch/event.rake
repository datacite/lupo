namespace :elasticsearch do
  namespace :event do
    desc "Create index for events"
    task :create_index => :environment do
      Event.__elasticsearch__.create_index!
    end

    desc "Delete index for events"
    task :delete_index => :environment do
      Event.__elasticsearch__.delete_index!
    end

    desc "Refresh index for events"
    task :refresh_index => :environment do
      Event.__elasticsearch__.refresh_index!
    end
  end
end