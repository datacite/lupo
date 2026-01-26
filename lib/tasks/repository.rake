# frozen_string_literal: true

namespace :repository do
  desc "Load all Clients into Reference Repostories"
  task load_client_repos: :environment do
    puts "Processing Client Repositories"
    Client.where(deleted_at: nil).each do |c|
      ReferenceRepository.create_from_client(c)
    end
  end

  desc "Load all Re3data Repositories into Reference Repostories"
  task :load_re3data_repos, [:pages] => :environment do |t, args|
    pages = (args[:pages] || 3).to_i
    re3repos = DataCatalog.fetch_and_cache_all(pages: pages)
    puts "Processing Re3Data Repositories"
    re3repos.each  do |repo|
      ReferenceRepository.create_from_re3repo(repo)
    end
  end

  desc "Create index for reference_repositories"
  task create_index: :environment do
    puts ReferenceRepository.create_index
  end

  desc "Delete index for reference_repositories"
  task delete_index: :environment do
    puts ReferenceRepository.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for reference_repositories"
  task upgrade_index: :environment do
    puts ReferenceRepository.upgrade_index
  end

  desc "Show index stats for reference_repositories"
  task index_stats: :environment do
    puts ReferenceRepository.index_stats
  end

  desc "Switch index for reference_repositories"
  task switch_index: :environment do
    puts ReferenceRepository.switch_index
  end

  desc "Return active index for reference_repositories"
  task active_index: :environment do
    puts ReferenceRepository.active_index + " is the active index."
  end

  desc "Monitor reindexing for reference_repositories"
  task monitor_reindex: :environment do
    puts ReferenceRepository.monitor_reindex
  end

  desc "Create alias for reference_repositories"
  task create_alias: :environment do
    puts ReferenceRepository.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for reference_repositories"
  task list_aliases: :environment do
    puts ReferenceRepository.list_aliases
  end

  desc "Delete alias for reference_repositories"
  task delete_alias: :environment do
    puts ReferenceRepository.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all reference_repositories"
  task :import, [:pages] => :environment do |t, args|
    pages = (args[:pages] || 3).to_i
    #DataCatalog.fetch_and_cache_all(pages: pages)
    ReferenceRepository.import(index: ReferenceRepository.inactive_index)
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts ReferenceRepository.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end
end
