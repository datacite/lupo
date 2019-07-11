namespace :provider do
  desc "Create index for providers"
  task :create_index => :environment do
    puts Provider.create_index
  end

  desc "Delete index for providers"
  task :delete_index => :environment do
    puts Provider.delete_index
  end

  desc "Upgrade index for providers"
  task :upgrade_index => :environment do
    puts Provider.upgrade_index
  end

  desc "Switch index for providers"
  task :switch_index => :environment do
    puts Provider.switch_index(force: ENV["FORCE"])
  end

  desc "Return active index for providers"
  task :active_index => :environment do
    puts Provider.active_index + " is the active index."
  end

  desc "Start using alias indexes for providers"
  task :start_aliases => :environment do
    puts Provider.start_aliases
  end

  desc "Monitor reindexing for providers"
  task :monitor_reindex => :environment do
    puts Provider.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for providers"
  task :finish_aliases => :environment do
    puts Provider.finish_aliases
  end

  desc 'Import all providers'
  task :import => :environment do
    Provider.import(index: Provider.inactive_index)
  end
end
