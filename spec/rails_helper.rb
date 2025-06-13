# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["TEST_CLUSTER_NODES"] = "1"
ENV["PREFIX_POOL_SIZE"] = "20"

# Set reasonable default environment variables for testing if not already set
ENV["TEST_ENV_NUMBER"] ||= "" # For parallel tests, often set by CI, default to empty
ENV["ES_PREFIX"] ||= "" # ElasticSearch index prefix
ENV["API_KEY"] ||= "test_api_key" # Placeholder for general API key
ENV["SESSION_ENCRYPTED_COOKIE_SALT"] ||= "a_strong_secret_key_for_testing_purposes"
ENV["VOLPINO_URL"] ||= "http://localhost:3000/api" # Placeholder for Volpino service
ENV["HANDLE_USERNAME"] ||= "test_handle_user"
ENV["HANDLE_URL"] ||= "http://handle.test.datacite.org"
ENV["HANDLE_PASSWORD"] ||= "test_handle_password"
ENV["BRACCO_URL"] ||= "http://doi.datacite.org"
ENV["BRACCO_TITLE"] ||= "DataCite Fabrica Test"
ENV["MAILGUN_API_KEY"] ||= "test_mailgun_api_key"
ENV["MG_FROM"] ||= "support@example.com"
ENV["MG_DOMAIN"] ||= "mg.example.com"
ENV["SLACK_WEBHOOK_URL"] ||= "" # Keep empty if not sending Slack notifications in tests
ENV["MDS_USERNAME"] ||= "DATACITE.TESTUSER"
ENV["MDS_PASSWORD"] ||= "test_mds_password"
ENV["ADMIN_USERNAME"] ||= "DATACITE.TESTADMIN"
ENV["ADMIN_PASSWORD"] ||= "test_admin_password"
ENV["PRIVATE_IP"] ||= "127.0.0.1" # Placeholder for local testing
ENV["ES_HOST"] ||= "elasticsearch:9200" # Assuming a local or test Elasticsearch instance
ENV["VCR_MODE"] ||= "once"
ENV["VCR"] ||= "once"
ENV["AWS_REGION"] ||= "us-east-1" # Placeholder if SQS is used, even if mocked
ENV["SQS_PREFIX"] ||= ""
ENV["APPLICATION"] ||= "client-api"
ENV["HOSTNAME"] ||= "lupo"
ENV["MEMCACHE_SERVERS"] ||= "memcached:11211"
ENV["SITE_TITLE"] ||= "DataCite REST API"
ENV["LOG_LEVEL"] ||= "info"
ENV["CONCURRENCY"] ||= "25"
ENV["API_URL"] ||= "http://localhost:4000"
ENV["CDN_URL"] ||= "http://localhost:9000"
ENV["GITHUB_URL"] ||= "https://github.com/datacite/lupo"
ENV["SEARCH_URL"] ||= "http://localhost:5000"
ENV["RE3DATA_URL"] ||= "https://www.re3data.org/api/beta"
ENV["CITEPROC_URL"] ||= "https://citation.crosscite.org/format"
ENV["MYSQL_DATABASE"] ||= "lupo_test"
ENV["MYSQL_USER"] ||= "root"
ENV["MYSQL_PASSWORD"] ||= ""
ENV["MYSQL_HOST"] ||= "mysql"
ENV["MYSQL_PORT"] ||= "3306"
ENV["ES_REQUEST_TIMEOUT"] ||= "120"
ENV["ES_NAME"] ||= "elasticsearch"
ENV["ES_SCHEME"] ||= "http"
ENV["ES_PORT"] ||= "80"
ENV["TRUSTED_IP"] ||= "10.0.40.1"
ENV["HANDLES_MINTED"] ||= "10132"
ENV["REALM"] ||= "http://localhost:4000"
ENV["EXCLUDE_PREFIXES_FROM_DATA_IMPORT"] ||= ""

# set up Code Climate
require "simplecov"
SimpleCov.start

require "openssl"

# Generate dummy JWT keys for testing if not already set
if ENV["JWT_PRIVATE_KEY"].nil? || ENV["JWT_PUBLIC_KEY"].nil?
  # Generate a new RSA key pair
  key = OpenSSL::PKey::RSA.new(2048)

  # Set private and public keys as environment variables
  ENV["JWT_PRIVATE_KEY"] = key.to_s
  ENV["JWT_PUBLIC_KEY"] = key.public_key.to_s
end

require File.expand_path("../config/environment", __dir__)

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

require "rspec/rails"
require "shoulda-matchers"
require "webmock/rspec"
require "rack/test"
require "colorize"
require "database_cleaner"
require "aasm/rspec"
require "strip_attributes/matchers"
require "rspec-benchmark"

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
