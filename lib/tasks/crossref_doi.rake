# frozen_string_literal: true

namespace :crossref_doi do
  desc "Create index for crossref dois"
  task :create_index => :environment do
    puts CrossrefDoi.create_index
  end

  desc "Delete index for crossref dois"
  task :delete_index => :environment do
    puts CrossrefDoi.delete_index
  end

  desc "Upgrade index for crossref dois"
  task :upgrade_index => :environment do
    puts CrossrefDoi.upgrade_index
  end

  desc "Show index stats for crossref dois"
  task :index_stats => :environment do
    puts CrossrefDoi.index_stats
  end

  desc "Switch index for crossref dois"
  task :switch_index => :environment do
    puts CrossrefDoi.switch_index
  end

  desc "Return active index for crossref dois"
  task :active_index => :environment do
    puts CrossrefDoi.active_index + " is the active index."
  end

  desc "Start using alias indexes for crossref dois"
  task :start_aliases => :environment do
    puts CrossrefDoi.start_aliases
  end

  desc "Monitor reindexing for crossref dois"
  task :monitor_reindex => :environment do
    puts CrossrefDoi.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for crossref dois"
  task :finish_aliases => :environment do
    puts CrossrefDoi.finish_aliases
  end

  desc 'Import all crossref DOIs'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i
    CrossrefDoi.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"] || CrossrefDoi.inactive_index)
  end
end
