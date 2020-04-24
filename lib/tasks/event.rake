# frozen_string_literal: true

namespace :event do
  desc "Create index for events"
  task :create_index => :environment do
    puts Event.create_index
  end

  desc "Delete index for events"
  task :delete_index => :environment do
    puts Event.delete_index
  end

  desc "Upgrade index for events"
  task :upgrade_index => :environment do
    puts Event.upgrade_index
  end

  desc "Show index stats for events"
  task :index_stats => :environment do
    puts Event.index_stats
  end

  desc "Switch index for events"
  task :switch_index => :environment do
    puts Event.switch_index(force: ENV["FORCE"])
  end

  desc "Return active index for events"
  task :active_index => :environment do
    puts Event.active_index + " is the active index."
  end

  desc "Start using alias indexes for events"
  task :start_aliases => :environment do
    puts Event.start_aliases
  end

  desc "Monitor reindexing for events"
  task :monitor_reindex => :environment do
    puts Event.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for events"
  task :finish_aliases => :environment do
    puts Event.finish_aliases
  end

  desc 'Import all events'
  task :import => :environment do
    from_id = (ENV['FROM_ID'] || Event.minimum(:id)).to_i
    until_id = (ENV['UNTIL_ID'] || Event.maximum(:id)).to_i

    Event.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"])
  end

  desc 'update registrant metadata'
  task :update_registrant => :environment do
    cursor = ENV['CURSOR'].to_s.split(",") || [Event.minimum(:id), Event.minimum(:id)]

    Event.update_registrant(cursor: cursor, size: ENV['SIZE'])
  end

  desc 'update target doi'
  task :update_target_doi => :environment do
    cursor = ENV['CURSOR'].to_s.split(",") || [Event.minimum(:id), Event.minimum(:id)]

    Event.update_target_doi(cursor: cursor, target_relation_type_id: ENV['TARGET_RELATION_TYPE_ID'], size: ENV['SIZE'])
  end
end

namespace :crossref do
  desc 'Import crossref dois for all events'
  task :import_doi => :environment do
    cursor = ENV['CURSOR'].to_s.split(",") || [Event.minimum(:id), Event.minimum(:id)]

    Event.update_crossref(cursor: cursor)
  end
end

namespace :subj_id_check do
  desc "checks that events subject node congruency"
  task check: :environment do
    from_id = (ENV["FROM_ID"] || Event.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Event.maximum(:id)).to_i
    Event.subj_id_check(from_id: from_id, until_id: until_id)
  end
end

namespace :crossref_events do
  desc "delete events labeled with crossref errors"
  task delete: :environment do
    options = {
      from_id: (ENV["FROM_ID"] || Event.minimum(:id)).to_i,
      until_id: (ENV["UNTIL_ID"] || Event.maximum(:id)).to_i,
      filter: { state_event: "crossref_citations_error" },
      label: "[DeleteEventwithCrossrefError]",
      job_name: "DeleteEventByAttributeJob",
    }
    Event.loop_through_events(options)
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
