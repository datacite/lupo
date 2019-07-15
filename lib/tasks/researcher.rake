namespace :researcher do
  desc "Create index for researchers"
  task :create_index => :environment do
    puts Researcher.create_index
  end

  desc "Delete index for researchers"
  task :delete_index => :environment do
    puts Researcher.delete_index
  end

  desc "Upgrade index for researchers"
  task :upgrade_index => :environment do
    puts Researcher.upgrade_index
  end

  desc "Show index stats for researchers"
  task :index_stats => :environment do
    puts Researcher.index_stats
  end

  desc "Switch index for researchers"
  task :switch_index => :environment do
    puts Researcher.switch_index
  end

  desc "Return active index for researchers"
  task :active_index => :environment do
    puts Researcher.active_index + " is the active index."
  end

  desc "Start using alias indexes for researchers"
  task :start_aliases => :environment do
    puts Researcher.start_aliases
  end

  desc "Monitor reindexing for researchers"
  task :monitor_reindex => :environment do
    puts Researcher.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for researchers"
  task :finish_aliases => :environment do
    puts Researcher.finish_aliases
  end

  desc 'Import all researchers'
  task :import => :environment do
    Researcher.import(index: Researcher.inactive_index)
  end
end