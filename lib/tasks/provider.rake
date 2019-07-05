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

  desc "reindex"
  task :reindex => :environment do
    if ENV['SOURCE_INDEX'].nil? || ENV['DEST_INDEX'].nil?
      puts "ENV['SOURCE_INDEX'] ENV['DEST_INDEX'] required"
      exit
    end

    Provider.__elasticsearch__.create_index! index: ENV['DEST_INDEX']

    client = Elasticsearch::Client.new log: true, host: ENV['ES_HOST']
    client.reindex body: { source: { index: ENV['SOURCE_INDEX'] }, dest: { index: ENV['DEST_INDEX'] } }
  end
end
