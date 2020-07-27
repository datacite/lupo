# frozen_string_literal: true

namespace :datacite_doi do
  desc "Create index for datacite dois"
  task :create_index => :environment do
    puts DataciteDoi.create_index
  end

  desc "Delete index for datacite dois"
  task :delete_index => :environment do
    puts DataciteDoi.delete_index
  end

  desc "Upgrade index for datacite dois"
  task :upgrade_index => :environment do
    puts DataciteDoi.upgrade_index
  end

  desc "Show index stats for datacite dois"
  task :index_stats => :environment do
    puts DataciteDoi.index_stats
  end

  desc "Switch index for datacite dois"
  task :switch_index => :environment do
    puts DataciteDoi.switch_index
  end

  desc "Return active index for datacite dois"
  task :active_index => :environment do
    puts DataciteDoi.active_index + " is the active index."
  end

  desc "Start using alias indexes for datacite dois"
  task :start_aliases => :environment do
    puts DataciteDoi.start_aliases
  end

  desc "Monitor reindexing for datacite dois"
  task :monitor_reindex => :environment do
    puts DataciteDoi.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for datacite dois"
  task :finish_aliases => :environment do
    puts DataciteDoi.finish_aliases
  end

  desc "Create template for datacite dois"
  task :create_template => :environment do
    puts DataciteDoi.create_template
  end

  desc "Delete template for datacite dois"
  task :delete_template => :environment do
    puts DataciteDoi.delete_template
  end

  desc "Delete aliases for dois"
  task :delete_alias => :environment do
    puts DataciteDoi.delete_alias
  end

  desc 'Import all datacite DOIs'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || DataciteDoi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || DataciteDoi.maximum(:id)).to_i

    puts DataciteDoi.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"]  || DataciteDoi.inactive_index)
  end

  desc 'Import one datacite DOI'
  task :import_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    puts DataciteDoi.import_one(doi_id: ENV['DOI'])
  end

  desc 'Index one datacite DOI'
  task :index_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    puts DataciteDoi.index_one(doi_id: ENV['DOI'])
  end
end
