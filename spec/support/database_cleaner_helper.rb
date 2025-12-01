RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner[:active_record].clean_with(:truncation) }

  config.before(:each) { DatabaseCleaner[:active_record].strategy = :transaction }

  config.before(:each, js: true) do
    DatabaseCleaner[:active_record].strategy = :truncation, { pre_count: true }
  end

  config.before(:each, trunk_db_before: true) do
    DatabaseCleaner[:active_record].clean_with(:truncation)
  end

  config.before(:each) { DatabaseCleaner[:active_record].start }

  config.after(:each) { DatabaseCleaner[:active_record].clean }
end
