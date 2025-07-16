# frozen_string_literal: true

namespace :other_doi do
  desc "Create index for other dois"
  task create_index: :environment do
    puts OtherDoi.create_index(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Delete index for other dois"
  task delete_index: :environment do
    puts OtherDoi.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for other dois"
  task upgrade_index: :environment do
    puts OtherDoi.upgrade_index(index: ENV["INDEX"])
  end

  desc "Set refresh interval for other dois"
  task set_refresh_interval: :environment do
    puts OtherDoi.set_refresh_interval(interval: ENV["INTERVAL"])
  end

  desc "Create alias for other dois"
  task create_alias: :environment do
    puts OtherDoi.create_alias(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Delete alias for other dois"
  task delete_alias: :environment do
    puts OtherDoi.delete_alias(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Show index stats for other dois"
  task index_stats: :environment do
    puts OtherDoi.index_stats(active_index: ENV["ACTIVE"], inactive_index: ENV["INACTIVE"])
  end

  desc "Switch index for other dois"
  task switch_index: :environment do
    puts OtherDoi.switch_index(alias: ENV["ALIAS"], index: ENV["INDEX"])
  end

  desc "Return active index for other dois"
  task active_index: :environment do
    puts OtherDoi.active_index + " is the active index."
  end

  desc "Monitor reindexing for other dois"
  task monitor_reindex: :environment do
    puts OtherDoi.monitor_reindex
  end

  desc "Create template for other dois"
  task create_template: :environment do
    puts OtherDoi.create_template
  end

  desc "Delete template for other dois"
  task delete_template: :environment do
    puts OtherDoi.delete_template
  end

  desc "Import all other DOIs"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || OtherDoi.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || OtherDoi.maximum(:id)).to_i
    shard_size = ENV["SHARD_SIZE"]&.to_i || 10_000
    batch_size = ENV["BATCH_SIZE"]&.to_i || 50
    selected_index = ENV["INDEX"] || OtherDoi.inactive_index
    puts OtherDoi.import_by_ids(
      from_id: from_id,
      until_id: until_id,
      index: selected_index,
      shard_size: shard_size,
      batch_size: batch_size
    )
  end

  desc "Import one other DOI"
  task import_one: :environment do
    if ENV["DOI"].nil? && ENV["ID"].nil?
      puts "Either ENV variable DOI or ID are required"
      exit
    end

    puts OtherDoi.import_one(doi_id: ENV["DOI"], id: ENV["ID"])
  end

  desc "Index one other DOI"
  task index_one: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    puts OtherDoi.index_one(doi_id: ENV["DOI"])
  end

  desc "Refresh metadata for other dois"
  task refresh: :environment do
    options = {
      query: ENV["QUERY"],
      label: "[RefreshMetadata]",
      job_name: "OtherDoiRefreshJob",
      cursor: ENV["CURSOR"],
    }
    puts OtherDoi.loop_through_dois(options)
  end
end
