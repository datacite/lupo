# frozen_string_literal: true

namespace :client do
  desc "Create index for clients"
  task create_index: :environment do
    puts Client.create_index
  end

  desc "Delete index for clients"
  task delete_index: :environment do
    puts Client.delete_index(index: ENV["INDEX"])
  end

  desc "Upgrade index for clients"
  task upgrade_index: :environment do
    puts Client.upgrade_index
  end

  desc "Show index stats for clients"
  task index_stats: :environment do
    puts Client.index_stats
  end

  desc "Switch index for clients"
  task switch_index: :environment do
    puts Client.switch_index
  end

  desc "Return active index for clients"
  task active_index: :environment do
    puts Client.active_index + " is the active index."
  end

  desc "Monitor reindexing for clients"
  task monitor_reindex: :environment do
    puts Client.monitor_reindex
  end

  desc "Create alias for clients"
  task create_alias: :environment do
    puts Client.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for clients"
  task list_aliases: :environment do
    puts Client.list_aliases
  end

  desc "Delete alias for clients"
  task delete_alias: :environment do
    puts Client.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all clients"
  task import: :environment do
    batch_size = ENV["BATCH_SIZE"].nil? ? 10 : ENV["BATCH_SIZE"].to_i

    Client.import(index: Client.inactive_index, batch_size: batch_size)
  end

  desc "Delete from index by query"
  task delete_by_query: :environment do
    if ENV["QUERY"].nil?
      puts "ENV['QUERY'] is required"
      exit
    end

    puts Client.delete_by_query(index: ENV["INDEX"], query: ENV["QUERY"])
  end

  # desc 'Index DOIs by client'
  # task :index_all_dois => :environment do
  #   if ENV['CLIENT_ID'].nil?
  #     puts "ENV['CLIENT_ID'] is required."
  #     exit
  #   end

  #   client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
  #   if client.nil?
  #     puts "Client not found for client ID #{ENV['CLIENT_ID']}."
  #     exit
  #   end

  #   # index DOIs for client
  #   # puts "#{client.dois.length} DOIs will be indexed."
  #   client.index_all_dois
  # end

  desc "Import DOIs by client"
  task import_dois: :environment do
    if ENV["CLIENT_ID"].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    Client.import_dois(ENV["CLIENT_ID"])
  end

  desc "Import dois not indexed"
  task import_dois_not_indexed: :environment do
    puts Client.import_dois_not_indexed(query: ENV["QUERY"])
  end

  desc "Export doi counts"
  task export_doi_counts: :environment do
    puts Client.export_doi_counts(query: ENV["QUERY"])
  end

  desc "Export all clients to Salesforce"
  task export: :environment do
    puts Client.export
  end

  desc "Export one client to Salesforce"
  task export_one: :environment do
    if ENV["CLIENT_ID"].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(symbol: ENV["CLIENT_ID"]).first
    if client.nil?
      puts "Client #{ENV["CLIENT_ID"]} not found."
      exit
    end

    client.send_client_export_message(client.to_jsonapi.merge(slack_output: true))
    puts "Exported metadata for client #{client.symbol}."
  end

  desc "Delete client transferred to other DOI registration agency"
  task delete: :environment do
    if ENV["CLIENT_ID"].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV["CLIENT_ID"]).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    # These prefixes are used by multiple clients
    prefixes_to_keep = %w(10.4124 10.4225 10.4226 10.4227)

    # delete all associated prefixes and DOIs
    prefixes = client.prefixes.where.not("prefixes.uid IN (?)", prefixes_to_keep).pluck(:uid)
    prefixes.each do |prefix|
      ENV["PREFIX"] = prefix
      Rake::Task["prefix:delete"].reenable
      Rake::Task["prefix:delete"].invoke
    end

    if client.update(is_active: nil, deleted_at: Time.zone.now)
      client.send_delete_email(responsible_id: "admin") unless Rails.env.test?
      puts "Client with client ID #{ENV['CLIENT_ID']} deleted."
    else
      puts client.errors.inspect
    end
  end

  desc "Transfer client"
  task transfer: :environment do
    if ENV["CLIENT_ID"].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV["CLIENT_ID"]).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    if ENV["TARGET_ID"].nil?
      puts "ENV['TARGET_ID'] is required."
      exit
    end

    target = Client.where(deleted_at: nil).where(symbol: ENV["TARGET_ID"]).first
    if target.nil?
      puts "Client not found for target ID #{ENV['TARGET_ID']}."
      exit
    end

    # These prefixes are used by multiple clients
    prefixes_to_keep = %w(10.4124 10.4225 10.4226 10.4227)

    # delete all associated prefixes
    prefixes = client.prefixes.where.not("prefixes.uid IN (?)", prefixes_to_keep)
    prefix_ids = client.prefixes.where.not("prefixes.uid IN (?)", prefixes_to_keep).pluck(:id)

    response = client.client_prefixes.destroy_all
    puts "#{response.count} client prefixes deleted."

    if prefix_ids.present?
      response = ProviderPrefix.where("prefix_id IN (?)", prefix_ids).destroy_all
      puts "#{response.count} provider prefixes deleted."
    end

    # update dois
    Doi.transfer(from_date: "2011-01-01", client_id: client.symbol, client_target_id: target.id)

    prefixes.each do |prefix|
      provider_prefix = ProviderPrefix.create(provider: target.provider, prefix: prefix)
      puts "Provider prefix for provider #{target.provider.symbol} and prefix #{prefix} created."
      ClientPrefix.create(client: target, prefix: prefix, provider_prefix: provider_prefix.id)
      puts "Client prefix for client #{target.symbol} and prefix #{prefix} created."
    end
  end

  desc "Delete client DOIs within a given date range"
  task delete_client_dois: :environment do
    # eg. CLIENT_ID='DATACITE.TEST' START_DATE=2025-09-01 END_DATE=2025-09-30 bin/rake client:delete_client_dois

    puts "======================================"
    puts " You are running this in: #{Rails.env.upcase}"
    puts "======================================"

    puts "Do you want to continue? (yes/no)"

    answer = $stdin.gets.chomp
    abort unless answer.downcase == "yes"

    client_id  = ENV["CLIENT_ID"]
    start_date = ENV["START_DATE"]
    end_date   = ENV["END_DATE"]

    abort "ENV['CLIENT_ID'] is required." if client_id.blank?
    abort "ENV['START_DATE'] and ENV['END_DATE'] are required." if start_date.blank? || end_date.blank?

    begin
      client = Client.find_by!(symbol: client_id)
    rescue ActiveRecord::RecordNotFound
      abort "Client not found for client ID #{client_id}."
    end

    begin
      start_date = Date.parse(start_date).beginning_of_day
      end_date   = Date.parse(end_date).end_of_day
    rescue ArgumentError => e
      abort "Invalid date provided: #{e.message}"
    end

    dois = client.dois.where(created_at: start_date..end_date)
    total = dois.count

    puts "Found #{total} DOIs for client #{client.symbol} between #{start_date} and #{end_date}."

    deleted = 0
    dois.find_in_batches(batch_size: 1000) do |batch|
      batch.each do |doi|
        doi.destroy
        deleted += 1
      end
      puts "Deleted #{deleted}/#{total} DOIs"
    end

    puts "Deleted #{deleted} DOIs for client #{client.symbol}."
  end
end
