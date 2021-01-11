# frozen_string_literal: true

namespace :prefix do
  desc "Create index for prefixes"
  task create_index: :environment do
    puts Prefix.create_index
  end

  desc "Delete index for prefixes"
  task delete_index: :environment do
    puts Prefix.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for prefixes"
  task upgrade_index: :environment do
    puts Prefix.upgrade_index
  end

  desc "Show index stats for prefixes"
  task index_stats: :environment do
    puts Prefix.index_stats
  end

  desc "Switch index for prefixes"
  task switch_index: :environment do
    puts Prefix.switch_index
  end

  desc "Return active index for prefixes"
  task active_index: :environment do
    puts Prefix.active_index + " is the active index."
  end

  desc "Return inactive index for prefixes"
  task inactive_index: :environment do
    puts Prefix.inactive_index + " is the inactive index."
  end

  desc "Monitor reindexing for prefixes"
  task monitor_reindex: :environment do
    puts Prefix.monitor_reindex
  end

  desc "Import all prefixes"
  task import: :environment do
    Prefix.import(index: ENV["INDEX"] || Prefix.inactive_index, batch_size: (ENV["BATCH_SIZE"] || 100).to_i)
  end

  desc "Create alias for prefixes"
  task create_alias: :environment do
    puts Prefix.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for prefixes"
  task list_aliases: :environment do
    puts Prefix.list_aliases
  end

  desc "Delete alias for prefixes"
  task delete_alias: :environment do
    puts Prefix.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts Prefix.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end

  desc "Get registration agency for each prefix"
  task registration_agency: :environment do
    puts Prefix.get_registration_agency
  end

  desc "Delete prefix and associated DOIs"
  task delete: :environment do
    # These prefixes are used by multiple prefixes and can't be deleted
    prefixes_to_keep = %w(10.4124 10.4225 10.4226 10.4227)

    if ENV["PREFIX"].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    if prefixes_to_keep.include?(ENV["PREFIX"])
      puts "Prefix #{ENV['PREFIX']} can't be deleted."
      exit
    end

    prefix = Prefix.where(uid: ENV["PREFIX"]).first
    if prefix.nil?
      puts "Prefix #{ENV['PREFIX']} not found."
      exit
    end

    ClientPrefix.where("prefix_id = ?", prefix.id).destroy_all
    puts "Client prefix deleted."

    ProviderPrefix.where("prefix_id = ?", prefix.id).destroy_all
    puts "Provider prefix deleted."

    prefix.destroy
    puts "Prefix #{ENV['PREFIX']} deleted."

    # delete DOIs
    count = Doi.delete_dois_by_prefix(ENV["PREFIX"])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} deleted."
  end
end
