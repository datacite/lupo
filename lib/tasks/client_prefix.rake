# frozen_string_literal: true

namespace :client_prefix do
  desc "Create index for client_prefixes"
  task create_index: :environment do
    puts ClientPrefix.create_index
  end

  desc "Delete index for client_prefixes"
  task delete_index: :environment do
    puts ClientPrefix.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for client_prefixes"
  task upgrade_index: :environment do
    puts ClientPrefix.upgrade_index
  end

  desc "Show index stats for client_prefixes"
  task index_stats: :environment do
    puts ClientPrefix.index_stats
  end

  desc "Switch index for client_prefixes"
  task switch_index: :environment do
    puts ClientPrefix.switch_index
  end

  desc "Return active index for client_prefixes"
  task active_index: :environment do
    puts ClientPrefix.active_index + " is the active index."
  end

  desc "Return inactive index for client_prefixes"
  task inactive_index: :environment do
    puts ClientPrefix.inactive_index + " is the inactive index."
  end

  desc "Monitor reindexing for client_prefixes"
  task monitor_reindex: :environment do
    puts ClientPrefix.monitor_reindex
  end

  desc "Import all client_prefixes"
  task import: :environment do
    ClientPrefix.import(index: ENV["INDEX"] || ClientPrefix.inactive_index, batch_size: (ENV["BATCH_SIZE"] || 100).to_i)
  end

  desc "Create alias for client_prefixes"
  task create_alias: :environment do
    puts ClientPrefix.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for client_prefixes"
  task list_aliases: :environment do
    puts ClientPrefix.list_aliases
  end

  desc "Delete alias for client_prefixes"
  task delete_alias: :environment do
    puts ClientPrefix.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts ClientPrefix.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end

  desc "Generate uid"
  task generate_uid: :environment do
    ClientPrefix.where(uid: [nil, ""]).each do |cp|
      cp.update_columns(uid: SecureRandom.uuid)
    end
  end
end
