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
    batch_size = ENV["BATCH_SIZE"].nil? ? 10 : ENV["BATCH_SIZE"].to_i

    Provider.import(index: Provider.inactive_index, batch_size: batch_size)
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

    provider.send_provider_export_message(provider.to_jsonapi.merge(slack_output: true))
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

  # This needs to be done only once. (migration)
  desc "Update provider contacts for all active providers"
  task set_all_provider_contacts: :environment do
    puts "Starting to update provider contacts..."

    Provider.where(deleted_at: nil).find_each do |provider|
      provider.set_provider_contacts
      provider.save
      provider.send_provider_export_message(provider.to_jsonapi.merge(slack_output: true))
      print "."
    rescue StandardError => e
      puts "\nFailed to update provider ID #{provider.id}: #{e.message}"
    end

    puts "\nFinished updating all provider contacts."
  end

  desc "Update one provider contacts (migration)"
  task set_one_provider_contacts: :environment do
    if ENV["PROVIDER_ID"].nil?
      puts "ENV['PROVIDER_ID'] is required."
      exit
    end

    provider = Provider.where(symbol: ENV["PROVIDER_ID"]).first
    if provider.nil?
      puts "Provider #{ENV["PROVIDER_ID"]} not found."
      exit
    end

    provider.set_provider_contacts
    provider.save
    provider.send_provider_export_message(provider.to_jsonapi.merge(slack_output: true))
    puts "Exported metadata for provider #{provider.symbol}."
  end

  # One-off: backfill annual_revenue from a CSV of For-profit Organizations exported from a Salesforce report before enabling
  # Fabrica -> Salesforce sync for this field.
  #
  # Expected CSV columns:
  #   Organization ID, Annual Revenue (For-Profit)
  #
  # Usage:
  #   DRY_RUN=true CSV_FILE=/path/to/export.csv bundle exec rake provider:backfill_annual_revenue
  #   DRY_RUN=false CSV_FILE=/path/to/export.csv bundle exec rake provider:backfill_annual_revenue
  desc "Backfill annual_revenue from Salesforce CSV (one-off)"
  task backfill_annual_revenue: :environment do
    require "csv"

    csv_file = ENV["CSV_FILE"].presence || ENV["FILE"].presence
    if csv_file.blank?
      puts "ENV['CSV_FILE'] is required (path to Salesforce CSV export)."
      exit 1
    end
    unless File.exist?(csv_file)
      puts "CSV file not found: #{csv_file}"
      exit 1
    end

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "true"))
    puts dry_run ? "Dry run (set DRY_RUN=false to apply)." : "Applying updates."

    stats = { rows: 0, skipped_blank: 0, not_found: 0, updated: 0 }

    CSV.foreach(csv_file, headers: true, encoding: "UTF-8") do |row|
      stats[:rows] += 1

      salesforce_id = row["Organization ID"].to_s.strip
      annual_revenue = row["Annual Revenue (For-Profit)"].to_s.strip

      if annual_revenue.blank?
        stats[:skipped_blank] += 1
        next
      end

      provider = Provider.where(salesforce_id: salesforce_id).first
      if provider.nil?
        stats[:not_found] += 1
        puts "Skip #{salesforce_id}: provider not found"
        next
      end

      if dry_run
        stats[:updated] += 1
        puts "Would update #{provider.symbol} (#{salesforce_id}): #{annual_revenue.inspect}"
        next
      end

      # Bypass validations/callbacks so raw SF values are stored and SF is not re-exported.
      provider.update_column(:annual_revenue, annual_revenue)
      stats[:updated] += 1
      puts "Updated #{provider.symbol} (#{salesforce_id}): #{annual_revenue.inspect}"
    end

    puts "\nSummary:"
    stats.each { |key, value| puts "  #{key}: #{value}" }
    puts dry_run ? "\nDry run complete. Re-run with DRY_RUN=false to apply." : "\nBackfill complete."
  end
end
