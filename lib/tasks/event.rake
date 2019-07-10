namespace :event do
  desc "Create index for events"
  task :create_index => :environment do
    initial_index = "events_v1"
    Event.__elasticsearch__.create_index!(index: initial_index)
    Event.create_alias(index: initial_index, alias_name: Event.index_name)
  end

  desc "Delete index for events"
  task :delete_index => :environment do
    #### It will delete the index rather than then trying to delete the alias
    Event.__elasticsearch__.delete_index!(index: Event.get_current_index_name)
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

  desc "Delete old Index"
  task :delete_old_index => :environment do
    Event.delete_old_index
  end

  desc "Create Alias"
  task :create_alias => :environment do
    Event.create_alias(index: ENV['INDEX_NAME'], alias_name:ENV['ALIAS_NAME'])
  end

  desc "Update Alias"
  task :update_alias => :environment do
    Event.update_aliases
  end

  desc "reindex the whole index"
  task :reindex => :environment do
    Event.reindex
  end

  desc "created versioned index"
  task :created_versioned => :environment do
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

namespace :datacite_medra do
  desc 'Import medra dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_medra(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end

namespace :datacite_kisti do
  desc 'Import kisti dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_kisti(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end

namespace :datacite_jalc do
  desc 'Import jalc dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_jalc(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end

namespace :datacite_op do
  desc 'Import op dois for all events'
  task :import_doi => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_op(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end

namespace :datacite_orcid_auto_update do
  desc 'Import orcid ids for all events'
  task :import_orcid => :environment do
    cursor = (ENV['CURSOR'] || Event.minimum(:id)).to_i

    Event.update_datacite_orcid_auto_update(cursor: cursor, refresh: ENV['REFRESH'], size: ENV['SIZE'])
  end
end
