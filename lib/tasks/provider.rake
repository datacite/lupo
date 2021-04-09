# frozen_string_literal: true

namespace :provider do
  desc "Create index for providers"
  task create_index: :environment do
    puts Provider.create_index
  end

  desc "Delete index for providers"
  task delete_index: :environment do
    puts Provider.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for providers"
  task upgrade_index: :environment do
    puts Provider.upgrade_index
  end

  desc "Show index stats for providers"
  task index_stats: :environment do
    puts Provider.index_stats
  end

  desc "Switch index for providers"
  task switch_index: :environment do
    puts Provider.switch_index
  end

  desc "Return active index for providers"
  task active_index: :environment do
    puts Provider.active_index + " is the active index."
  end

  desc "Monitor reindexing for providers"
  task monitor_reindex: :environment do
    puts Provider.monitor_reindex
  end

  desc "Create alias for providers"
  task create_alias: :environment do
    puts Provider.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for providers"
  task list_aliases: :environment do
    puts Provider.list_aliases
  end

  desc "Delete alias for providers"
  task delete_alias: :environment do
    puts Provider.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all providers"
  task import: :environment do
    Provider.import(index: Provider.inactive_index)
  end

  desc "Export all providers to Salesforce"
  task export: :environment do
    puts Provider.export
  end

  desc "Export one provider to Salesforce"
  task export_one: :environment do
    if ENV["PROVIDER_ID"].nil?
      puts "ENV['PROVIDER_ID'] is required."
      exit
    end

    provider = Provider.where(symbol: ENV["PROVIDER_ID"]).first
    if provider.nil?
      puts "Provider #{ENV["PROVIDER_ID"]} not found."
      exit
    end

    provider.send_provider_export_message(provider.to_jsonapi)
    puts "Exported metadata for provider #{provider.symbol}."
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts Provider.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end
end
