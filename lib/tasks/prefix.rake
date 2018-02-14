namespace :client_prefix do
  desc 'Make id for datacentre_prefixes table random'
  task :random => :environment do
    ClientPrefix.find_each do |cp|
      cp.send(:set_id)
      cp.save
    end
  end

  desc 'Set created date from prefix'
  task :created => :environment do
    ClientPrefix.where(created_at: nil).find_each do |cp|
      cp.update_column(:created_at, cp.prefix.created)
    end
  end

  desc 'Set provider_prefix association'
  task :set_provider => :environment do
    ClientPrefix.where(allocator_prefixes: nil).find_each do |cp|
      cp.send(:set_allocator_prefixes)
      cp.save
    end
  end
end

namespace :provider_prefix do
  desc 'Make id for allocator_prefixes table random'
  task :random => :environment do
    ProviderPrefix.find_each do |pp|
      pp.send(:set_id)
      pp.save
    end
  end

  desc 'Set created date from prefix'
  task :created => :environment do
    ProviderPrefix.where(created_at: nil).find_each do |pp|
      pp.update_column(:created_at, pp.prefix.created)
    end
  end
end

namespace :client do
  desc 'Set test prefix'
  task :set_test_prefix => :environment do
    Client.find_each do |c|
      c.send(:set_test_prefix)
      c.save
    end
  end
end

namespace :provider do
  desc 'Set test prefix'
  task :set_test_prefix => :environment do
    Provider.find_each do |p|
      p.send(:set_test_prefix)
      p.save
    end
  end
end

namespace :prefix do
  desc 'Create test prefix'
  task :create_test_prefix => :environment do
    unless Prefix.where(prefix: "10.5072").first
      Prefix.new(prefix: "10.5072") do |p|
        p.save
      end
    end
  end
end
