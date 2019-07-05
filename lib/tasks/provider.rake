namespace :provider do
  desc 'Import all providers'
  task :import => :environment do
    Provider.__elasticsearch__.create_index!
    Provider.import
  end

  desc "Create index for providers"
  task :create_index => :environment do
    Provider.__elasticsearch__.create_index!
  end

  desc "Delete index for providers"
  task :delete_index => :environment do
    Provider.__elasticsearch__.delete_index!
  end

  desc "Refresh index for providers"
  task :refresh_index => :environment do
    Provider.__elasticsearch__.refresh_index!
  end

  desc "Create Alias"
  task :create_alias => :environment do
    Provider.create_alias(index: ENV['INDEX_NAME'])
  end

  desc "reindex"
  task :reindex => :environment do
    Provider.reindex(index: ENV['INDEX_NAME'])
  end
end
