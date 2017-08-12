ENV['RAILS_ENV'] = 'test'

# set up Code Climate
require 'simplecov'
SimpleCov.start

require File.expand_path('../../config/environment', __FILE__)

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
require "rspec/rails"
require "shoulda-matchers"
require "webmock/rspec"
require "rack/test"
require "colorize"
require 'database_cleaner'

# Checks for pending migration and applies them before tests are run.
ActiveRecord::Migration.maintain_test_schema!

# configure shoulda matchers to use rspec as the test framework and full matcher libraries for rails
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # add `FactoryGirl` methods
  config.include FactoryGirl::Syntax::Methods
  
  # add custom json method
  config.include RequestSpecHelper, type: :request

  # start by truncating all the tables but then use the faster transaction strategy the rest of the time.
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  # start the transaction strategy as examples are run
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
