namespace :prefix do
  desc 'Delete prefix and associated DOIs'
  task :delete => :environment do
    # These prefixes are used by multiple clients and can't be deleted
    prefixes_to_keep = %w(10.5072 10.4124 10.4225 10.4226 10.4227)

    if ENV['PREFIX'].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    if prefixes_to_keep.include?(ENV['PREFIX'])
      puts "Prefix #{ENV['PREFIX']} can't be deleted."
      exit
    end

    prefix = Prefix.where(prefix: ENV['PREFIX']).first
    if prefix.nil?
      puts "Prefix #{ENV['PREFIX']} not found."
      exit
    end

    ClientPrefix.where('prefixes = ?', prefix.id).destroy_all
    puts "Client prefix deleted."

    ProviderPrefix.where('prefixes = ?', prefix.id).destroy_all
    puts "Provider prefix deleted."

    prefix.destroy
    puts "Prefix #{ENV['PREFIX']} deleted."

    # delete DOIs
    count = Doi.delete_dois_by_prefix(ENV['PREFIX'])
    puts "#{count} DOIs with prefix #{ENV['PREFIX']} deleted."
  end
end
