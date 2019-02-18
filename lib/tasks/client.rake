namespace :client do
  desc "Create index for clients"
  task :create_index => :environment do
    Client.__elasticsearch__.create_index!
  end

  desc "Delete index for clients"
  task :delete_index => :environment do
    Client.__elasticsearch__.delete_index!
  end

  desc "Refresh index for clients"
  task :refresh_index => :environment do
    Client.__elasticsearch__.refresh_index!
  end

  desc 'Index DOIs by client'
  task :index_all_dois => :environment do
    if ENV['CLIENT_ID'].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    # index DOIs for client
    # puts "#{client.dois.length} DOIs will be indexed."
    client.index_all_dois
  end

  desc 'Import all clients'
  task :import => :environment do
    Client.import
  end

  desc 'Import DOIs by client'
  task :import_all_dois => :environment do
    if ENV['CLIENT_ID'].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    # import DOIs for client
    # puts "#{client.dois.length} DOIs will be imported."
    client.import_all_dois
  end

  desc 'Import missing DOIs by client'
  task :import_missing_dois => :environment do
    if ENV['CLIENT_ID'].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    # import DOIs for client
    # puts "#{client.dois.length} DOIs will be imported."
    client.import_missing_dois
  end

  desc 'Delete client transferred to other DOI registration agency'
  task :delete => :environment do
    if ENV['CLIENT_ID'].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    # These prefixes are used by multiple clients
    prefixes_to_keep = %w(10.5072 10.4124 10.4225 10.4226 10.4227)

    # delete all associated prefixes and DOIs
    prefixes = client.prefixes.where.not('prefix IN (?)', prefixes_to_keep).pluck(:prefix)
    prefix_ids = client.prefixes.where.not('prefix IN (?)', prefixes_to_keep).pluck(:id)

    response = client.client_prefixes.destroy_all
    puts "#{response.count} client prefixes deleted."

    if prefix_ids.present?
      response = ProviderPrefix.where('prefixes IN (?)', prefix_ids).destroy_all
      puts "#{response.count} provider prefixes deleted."
    end

    if prefixes.present?
      response = Prefix.where('prefix IN (?)', prefixes).destroy_all
      puts "Prefixes #{prefixes.join(" and ")} deleted."
    end

    # delete DOIs in batches
    puts "#{client.dois.length} DOIs will be deleted."
    client.dois.find_each do |doi|
      doi.destroy
      puts "DOI #{doi.doi} deleted."
    end
    
    if client.update_attributes(is_active: nil, deleted_at: Time.zone.now)
      client.send_delete_email unless Rails.env.test?
      puts "Client with client ID #{ENV['CLIENT_ID']} deleted."
    else
      puts client.errors.inspect
    end
  end

  desc 'Transfer client'
  task :transfer => :environment do
    if ENV['CLIENT_ID'].nil?
      puts "ENV['CLIENT_ID'] is required."
      exit
    end

    client = Client.where(deleted_at: nil).where(symbol: ENV['CLIENT_ID']).first
    if client.nil?
      puts "Client not found for client ID #{ENV['CLIENT_ID']}."
      exit
    end

    if ENV['TARGET_ID'].nil?
      puts "ENV['TARGET_ID'] is required."
      exit
    end

    target = Client.where(deleted_at: nil).where(symbol: ENV['TARGET_ID']).first
    if target.nil?
      puts "Client not found for target ID #{ENV['TARGET_ID']}."
      exit
    end

    # These prefixes are used by multiple clients
    prefixes_to_keep = %w(10.5072 10.4124 10.4225 10.4226 10.4227)

    # delete all associated prefixes
    prefixes = client.prefixes.where.not('prefix IN (?)', prefixes_to_keep).pluck(:prefix)
    prefix_ids = client.prefixes.where.not('prefix IN (?)', prefixes_to_keep).pluck(:id)

    response = client.client_prefixes.destroy_all
    puts "#{response.count} client prefixes deleted."

    if prefix_ids.present?
      response = ProviderPrefix.where('prefixes IN (?)', prefix_ids).destroy_all
      puts "#{response.count} provider prefixes deleted."
    end

    # update dois
    Doi.transfer(from_date: "2011-01-01", client_id: client.id, target_id: target.id)

    prefixes.each do |prefix|
      provider_prefix = ProviderPrefix.create(provider: target.provider.symbol, prefix: prefix)
      puts "Provider prefix for provider #{target.provider.symbol} and prefix #{prefix} created."
      client_prefix = ClientPrefix.create(client: target.symbol, prefix: prefix, provider_prefix: provider_prefix.id)
      puts "Client prefix for client #{target.symbol} and prefix #{prefix} created."
    end
  end
end