# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to doi with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.seconds.to_i}",
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true
  config.cache_store = :mem_cache_store, ENV["MEMCACHE_SERVERS"], {
    namespace: ENV["APPLICATION"],
    pool: {
      size: (ENV["CONCURRENCY"] || 10).to_i + 10,
      timeout: (ENV["MEMCACHE_POOL_TIMEOUT"] || 5).to_i
    }
  }

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  # config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  # config.action_mailer.delivery_method = :test

  # set Active Job queueing backend
  config.active_job.queue_adapter = :inline

  config.active_storage.service = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # config.after_initialize do
  #   Bullet.enable = true
  #   Bullet.rails_logger = true
  #   Bullet.raise = true
  #   Bullet.counter_cache_enable = false
  # end
  config.log_level = :ERROR

  # Set reasonable default environment variables for testing if not already set
  ENV["TEST_ENV_NUMBER"] ||= "" # For parallel tests, often set by CI, default to empty
  ENV["ES_PREFIX"] ||= "" # ElasticSearch index prefix
  ENV["API_KEY"] ||= "test_api_key" # Placeholder for general API key
  ENV["SESSION_ENCRYPTED_COOKIE_SALT"] ||= "a_strong_secret_key_for_testing_purposes"
  ENV["VOLPINO_URL"] ||= "http://localhost:3000/api" # Placeholder for Volpino service
  ENV["HANDLE_USERNAME"] ||= "test_handle_user"
  ENV["HANDLE_URL"] ||= "https://handle.test.datacite.org"
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
  ENV["MONTHLY_DATAFILE_BUCKET"] ||= "monthly-datafile.stage.datacite.org"
  ENV["MONTHLY_DATAFILE_ACCESS_ROLE"] ||= ""
end
