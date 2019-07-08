namespace :event do
  desc "Create index for events"
  task :create_index => :environment do
    alias_name = Event.index_name
    Event.__elasticsearch__.create_index!(index: ENV['INDEX_NAME'])
    Event.create_alias(index: ENV['INDEX_NAME'], alias_name:alias_name)
  end

  desc "Delete index for events"
  task :delete_index => :environment do
    #### It will delete the index rather than then trying to delete the alias
    Event.__elasticsearch__.delete_index!(index: ENV['INDEX_NAME']||=Event.get_current_index_name)
  end

  desc "Refresh index for events"
  task :refresh_index => :environment do
    Event.__elasticsearch__.refresh_index!
  end

  desc 'Import all events'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || Event.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Event.maximum(:id)).to_i

    Event.import_by_ids(from_id: from_id, until_id: until_id)
  end

  desc "Get Current Index name"
  task :get_current_index_name => :environment do
    puts "Current index name is #{Event.get_current_index_name}"
  end

  desc "Delete unused Index"
  task :delete_unused_index => :environment do
    Event.delete_unused_index(index: ENV['INDEX_NAME'])
  end

  desc "Create Alias"
  task :create_alias => :environment do
    Event.create_alias(index: ENV['INDEX_NAME'], alias_name:ENV['ALIAS_NAME'])
  end

  desc "Update Alias"
  task :update_alias => :environment do
    Event.update_aliases(old_index: ENV['OLD_INDEX'], new_index: ENV['NEW_INDEX'])
  end

  desc "reindex the whole index"
  task :reindex => :environment do
    Event.reindex(index: ENV['INDEX_NAME'])
  end
end

namespace :crossref do
  desc 'Import crossref dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_crossref(cursor: cursor)
  end
end

namespace :datacite_crossref do
  desc 'Import crossref dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_crossref(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end

namespace :datacite_orcid_auto_update do
  desc 'Import orcid ids for all events'
  task :import_orcid => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_orcid_auto_update(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end
