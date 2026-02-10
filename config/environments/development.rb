# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # config.action_controller.perform_caching = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false
  #
  # config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.active_storage.service = :local

  config.active_job.queue_adapter = :inline

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  require "flipper/middleware/memoizer"
  config.middleware.use Flipper::Middleware::Memoizer
  config.flipper.memoize = false
  config.hosts << "lupo_web"
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

BetterErrors::Middleware.allow_ip! ENV["TRUSTED_IP"]
