# frozen_string_literal: true

namespace :provider_prefix do
  desc "Create index for provider_prefixes"
  task :create_index => :environment do
    puts ProviderPrefix.create_index
  end

  desc "Delete index for provider_prefixes"
  task :delete_index => :environment do
    puts ProviderPrefix.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for provider_prefixes"
  task :upgrade_index => :environment do
    puts ProviderPrefix.upgrade_index
  end

  desc "Show index stats for provider_prefixes"
  task :index_stats => :environment do
    puts ProviderPrefix.index_stats
  end

  desc "Switch index for provider_prefixes"
  task :switch_index => :environment do
    puts ProviderPrefix.switch_index
  end

  desc "Return active index for provider_prefixes"
  task :active_index => :environment do
    puts ProviderPrefix.active_index + " is the active index."
  end

  desc "Monitor reindexing for provider_prefixes"
  task :monitor_reindex => :environment do
    puts ProviderPrefix.monitor_reindex
  end

  desc 'Import all provider_prefixes'
  task :import => :environment do
    ProviderPrefix.import(index: ENV["INDEX"] || ProviderPrefix.inactive_index, batch_size: (ENV["BATCH_SIZE"] || 100).to_i)
  end

  desc 'Generate uid'
  task :generate_uid => :environment do
    ProviderPrefix.where(uid: [nil, ""]).each do |pp|
      pp.update_columns(uid: SecureRandom.uuid)
    end
  end
end


