# frozen_string_literal: true

namespace :activity do
  desc "Create index for activities"
  task create_index: :environment do
    puts Activity.create_index
  end

  desc "Delete index for activities"
  task delete_index: :environment do
    puts Activity.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for activities"
  task upgrade_index: :environment do
    puts Activity.upgrade_index
  end

  desc "Show index stats for activities"
  task index_stats: :environment do
    puts Activity.index_stats
  end

  desc "Switch index for activities"
  task switch_index: :environment do
    puts Activity.switch_index
  end

  desc "Return active index for activities"
  task active_index: :environment do
    puts Activity.active_index + " is the active index."
  end

  desc "Monitor reindexing for activities"
  task monitor_reindex: :environment do
    puts Activity.monitor_reindex
  end

  desc "Create alias for activities"
  task create_alias: :environment do
    puts Activity.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all activities"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || 1).to_i
    until_id = (ENV["UNTIL_ID"] || Activity.maximum(:id)).to_i

    Activity.import_by_ids(from_id: from_id, until_id: until_id)
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts Activity.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end

  desc "Convert affiliations to new format"
  task convert_affiliations: :environment do
    from_id = (ENV["FROM_ID"] || Doi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Doi.maximum(:id)).to_i

    Activity.convert_affiliations(from_id: from_id, until_id: until_id)
  end
end
