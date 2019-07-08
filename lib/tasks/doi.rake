namespace :doi do
  desc "Create index for dois"
  task :create_index => :environment do
    Doi.__elasticsearch__.create_index!
  end

  desc "Delete index for dois"
  task :delete_index => :environment do
    Doi.__elasticsearch__.delete_index!
  end

  desc "Refresh index for dois"
  task :refresh_index => :environment do
    Doi.__elasticsearch__.refresh_index!
  end

  desc 'Import all DOIs'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || Doi.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Doi.maximum(:id)).to_i

    Doi.import_by_ids(from_id: from_id, until_id: until_id)
  end

  desc 'Import one DOI'
  task :import_one => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    Doi.import_one(doi_id: ENV['DOI'])
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

  desc 'Delete DOIs with test prefix older than one month'
  task :delete_test_dois => :environment do
    from_date = ENV['FROM_DATE'] || Time.zone.now - 1.month
    Doi.delete_test_dois(from_date: from_date)
  end

  desc 'Migrates landing page data handling camelCase changes at same time'
  task :migrate_landing_page => :environment do
    Doi.migrate_landing_page
  end

  desc "Get Current Index name"
  task :get_current_index_name => :environment do
    Doi.get_current_index_name
  end

  desc "Delete unused Index"
  task :delete_unused_index => :environment do
    Doi.delete_unused_index(index: ENV['INDEX_NAME'])
  end

  desc "Create Alias"
  task :create_alias => :environment do
    Doi.create_alias(index: ENV['INDEX_NAME'])
  end

  desc "Update Alias"
  task :update_alias => :environment do
    Doi.update_aliases(old_index: ENV['OLD_INDEX'], new_index: ENV['NEW_INDEX'])
  end


  desc "reindex"
  task :reindex => :environment do
    Doi.reindex(index: ENV['INDEX_NAME'])
  end
end
