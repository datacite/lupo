# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["TEST_CLUSTER_NODES"] = "1"
ENV["PREFIX_POOL_SIZE"] = "20"

# set up Code Climate
require "simplecov"
SimpleCov.start

require "openssl"
require File.expand_path("../config/environment", __dir__)

# Generate dummy JWT keys for testing if not already set
if ENV["JWT_PRIVATE_KEY"].nil? || ENV["JWT_PUBLIC_KEY"].nil?
  # Use existing test certificates
  ENV["JWT_PRIVATE_KEY"] = File.read(Rails.root.join("spec", "fixtures", "certs", "rsa-2048-private.pem"))
  ENV["JWT_PUBLIC_KEY"] = File.read(Rails.root.join("spec", "fixtures", "certs", "rsa-2048-public.pem"))
end

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

require "rspec/rails"
require "shoulda-matchers"
require "webmock/rspec"
require "rack/test"
require "colorize"
require "database_cleaner/active_record"
require "aasm/rspec"
require "strip_attributes/matchers"
require "rspec-benchmark"

if ENV["METADATA_STORAGE_BUCKET_NAME"].present?
  ENV["METADATA_STORAGE_BUCKET_NAME"] = ENV["METADATA_STORAGE_BUCKET_NAME"] + "-test#{ENV["TEST_ENV_NUMBER"]}"
end


# Checks for pending migration and applies them before tests are run.
ActiveRecord::Migration.maintain_test_schema!

WebMock.disable_net_connect!(
  allow: ["codeclimate.com:443", ENV["PRIVATE_IP"], ENV["ES_HOST"]],
  allow_localhost: true,
)

# configure shoulda matchers to use rspec as the test framework and full matcher libraries for rails
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.order = "random"

  config.include FactoryBot::Syntax::Methods
  config.include StripAttributes::Matchers
  config.include RSpec::Benchmark::Matchers
  config.include Rack::Test::Methods, type: :request
  config.include RSpec::GraphqlMatchers::TypesHelper
  config.include ActiveSupport::Testing::TimeHelpers

  # don't use transactions, use database_clear gem via support file
  config.use_transactional_fixtures = false

  # add custom json method
  config.include RequestHelper, type: :request

  config.include JobHelper, type: :job

  ActiveJob::Base.queue_adapter = :test

  if Bullet.enable?
    config.before(:each) { Bullet.start_request }

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  config.before(:each, :monitor_factories) do |example|
    ActiveSupport::Notifications.subscribe("factory_bot.run_factory") do |name, start, finish, id, payload|
      $stderr.puts "FactoryBot: #{payload[:strategy]}(:#{payload[:name]}) at #{start}"
    end
  end

  config.before(:suite) do
    puts("Clearing_cache")
    Rails.cache.clear
    puts("Caching re3data")
    VCR.use_cassette("DataCatalog/cache_warmer") do
      DataCatalog.fetch_and_cache_all(pages: 3, duration: 30.minutes)
    end
  end

  config.before(:each) do |example|
    # Checking if :skip_prefix_pool parameter is set in metadata
    if example.metadata[:skip_prefix_pool]
      # Skip the prefix pool setup
      next
    end

    prefix_pool_size = example.metadata[:prefix_pool_size].present? ? example.metadata[:prefix_pool_size].to_i : ENV["PREFIX_POOL_SIZE"].to_i
    if prefix_pool_size <= 0
      @prefix_pool = []
    else
      @prefix_pool = create_list(:prefix, prefix_pool_size)
    end
    Prefix.import
  end

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = nil
  end
end

VCR.configure do |c|
  /rec/i.match?(ENV["VCR_MODE"]) ? :all : :once

  record_mode = ENV["VCR"] ? ENV["VCR"].to_sym : :once
  c.default_cassette_options = { record: record_mode }

  mds_token =
    Base64.strict_encode64("#{ENV['MDS_USERNAME']}:#{ENV['MDS_PASSWORD']}")
  admin_token =
    Base64.strict_encode64("#{ENV['ADMIN_USERNAME']}:#{ENV['ADMIN_PASSWORD']}")
  handle_token =
    Base64.strict_encode64(
      "300%3A#{ENV['HANDLE_USERNAME']}:#{ENV['HANDLE_PASSWORD']}",
    )
  mailgun_token = Base64.strict_encode64("api:#{ENV['MAILGUN_API_KEY']}")
  sqs_host = "sqs.#{Aws.config[:region]}.amazonaws.com"

  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts "codeclimate.com", "api.mailgun.net", "elasticsearch", sqs_host
  c.filter_sensitive_data("<MDS_TOKEN>") { mds_token }
  c.filter_sensitive_data("<ADMIN_TOKEN>") { admin_token }
  c.filter_sensitive_data("<HANDLE_TOKEN>") { handle_token }
  c.filter_sensitive_data("<MAILGUN_TOKEN>") { mailgun_token }
  c.filter_sensitive_data("<VOLPINO_TOKEN>") { ENV["VOLPINO_TOKEN"] }
  c.filter_sensitive_data("<SLACK_WEBHOOK_URL>") { ENV["SLACK_WEBHOOK_URL"] }
  c.configure_rspec_metadata!
  c.default_cassette_options = { match_requests_on: %i[method uri] }
  # c.debug_logger = $stderr
end

def capture_stdout
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end
