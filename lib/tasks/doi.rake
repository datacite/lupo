# frozen_string_literal: true

namespace :doi do
  desc "Create index for dois"
  task :create_index => :environment do
    puts Doi.create_index
  end

  desc "Delete index for dois"
  task :delete_index => :environment do
    puts Doi.delete_index
  end

  desc "Upgrade index for dois"
  task :upgrade_index => :environment do
    puts Doi.upgrade_index
  end

  desc "Show index stats for dois"
  task :index_stats => :environment do
    puts Doi.index_stats
  end

  desc "Switch index for dois"
  task :switch_index => :environment do
    puts Doi.switch_index
  end

  desc "Return active index for dois"
  task :active_index => :environment do
    puts Doi.active_index + " is the active index."
  end

  desc "Start using alias indexes for dois"
  task :start_aliases => :environment do
    puts Doi.start_aliases
  end

  desc "Monitor reindexing for dois"
  task :monitor_reindex => :environment do
    puts Doi.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for dois"
  task :finish_aliases => :environment do
    puts Doi.finish_aliases
  end

  desc 'Import all DOIs'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    Doi.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"])
  end

  desc 'Import one DOI'
  task :import_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    Doi.import_one(doi_id: ENV['DOI'])
  end

  desc 'Index one DOI'
  task :index_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    Doi.index_one(doi_id: ENV['DOI'])
  end

  desc 'Store handle URL'
  task :set_url => :environment do
    Doi.set_url
  end

  desc 'Set handle'
  task :set_handle => :environment do
    Doi.set_handle
  end

  desc 'Set minted'
  task :set_minted => :environment do
    Doi.set_minted
  end

  desc 'Convert affiliations to new format'
  task :convert_affiliations => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    Doi.convert_affiliations(from_id: from_id, until_id: until_id)
  end

  desc 'Convert containers to new format'
  task :convert_containers => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    Doi.convert_containers(from_id: from_id, until_id: until_id)
  end

  desc 'Migrates landing page data handling camelCase changes at same time'
  task :migrate_landing_page => :environment do
    Doi.migrate_landing_page
  end

  desc 'Delete dois by a prefix'
  task :delete_by_prefix => :environment do
    if ENV['PREFIX'].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    puts "Note: This does not delete any associated prefix."

    count = Doi.delete_dois_by_prefix(ENV['PREFIX'])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} deleted."
  end
end
