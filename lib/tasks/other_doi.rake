# frozen_string_literal: true

namespace :other_doi do
  desc "Create index for other dois"
  task :create_index => :environment do
    puts OtherDoi.create_index
  end

  desc "Delete index for other dois"
  task :delete_index => :environment do
    puts OtherDoi.delete_index
  end

  desc "Upgrade index for other dois"
  task :upgrade_index => :environment do
    puts OtherDoi.upgrade_index
  end

  desc "Show index stats for other dois"
  task :index_stats => :environment do
    puts OtherDoi.index_stats
  end

  desc "Switch index for other dois"
  task :switch_index => :environment do
    puts OtherDoi.switch_index
  end

  desc "Return active index for other dois"
  task :active_index => :environment do
    puts OtherDoi.active_index + " is the active index."
  end

  desc "Start using alias indexes for other dois"
  task :start_aliases => :environment do
    puts OtherDoi.start_aliases
  end

  desc "Monitor reindexing for other dois"
  task :monitor_reindex => :environment do
    puts OtherDoi.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for other dois"
  task :finish_aliases => :environment do
    puts OtherDoi.finish_aliases
  end

  desc 'Import all other DOIs'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || OtherDoi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || OtherDoi.maximum(:id)).to_i
    puts OtherDoi.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"] || OtherDoi.inactive_index)
  end

  desc 'Import one other DOI'
  task :import_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    puts OtherDoi.import_one(doi_id: ENV['DOI'])
  end

  desc 'Index one other DOI'
  task :index_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    puts OtherDoi.index_one(doi_id: ENV['DOI'])
  end
end
