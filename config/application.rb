# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "rails/test_unit/railtie"
require "active_job/logging"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# load ENV variables from .env file if it exists
env_file = File.expand_path("../.env", __dir__)
if File.exist?(env_file)
  require "dotenv"
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

# default values for some ENV variables
ENV["APPLICATION"] ||= "client-api"
ENV["HOSTNAME"] ||= "lupo"
ENV["MEMCACHE_SERVERS"] ||= "memcached:11211"
ENV["SITE_TITLE"] ||= "DataCite REST API"
ENV["LOG_LEVEL"] ||= "info"
ENV["CONCURRENCY"] ||= "25"
ENV["API_URL"] ||= "https://api.stage.datacite.org"
ENV["CDN_URL"] ||= "https://assets.datacite.org"
ENV["BRACCO_URL"] ||= "https://doi.datacite.org"
ENV["BRACCO_TITLE"] ||= "DataCite Fabrica"
ENV["GITHUB_URL"] ||= "https://github.com/datacite/lupo"
ENV["SEARCH_URL"] ||= "https://search.datacite.org/"
ENV["VOLPINO_URL"] ||= "https://profiles.datacite.org/api"
ENV["RE3DATA_URL"] ||= "https://www.re3data.org/api/beta"
ENV["CITEPROC_URL"] ||= "https://citation.crosscite.org/format"
ENV["HANDLE_URL"] ||= "https://handle.test.datacite.org"
ENV["MYSQL_DATABASE"] ||= "lupo"
ENV["MYSQL_USER"] ||= "root"
ENV["MYSQL_PASSWORD"] ||= ""
ENV["MYSQL_HOST"] ||= "mysql"
ENV["MYSQL_PORT"] ||= "3306"
ENV["ES_REQUEST_TIMEOUT"] ||= "120"
ENV["ES_HOST"] ||= "elasticsearch:9200"
ENV["ES_NAME"] ||= "elasticsearch"
ENV["ES_SCHEME"] ||= "http"
ENV["ES_PORT"] ||= "80"
ENV["ES_PREFIX"] ||= ""
ENV["TRUSTED_IP"] ||= "10.0.40.1"
ENV["MG_FROM"] ||= "support@datacite.org"
ENV["MG_DOMAIN"] ||= "mg.datacite.org"
ENV["HANDLES_MINTED"] ||= "10132"
ENV["REALM"] ||= ENV["API_URL"]
ENV["SQS_PREFIX"] ||= ""

module Lupo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # include graphql
    config.paths.add Rails.root.join("app", "graphql", "types").to_s,
                     eager_load: true
    config.paths.add Rails.root.join("app", "graphql", "mutations").to_s,
                     eager_load: true
    config.paths.add Rails.root.join("app", "graphql", "connections").to_s,
                     eager_load: true
    config.paths.add Rails.root.join("app", "graphql", "resolvers").to_s,
                     eager_load: true

    # Allow middleware to be loaded. (compressed_requests)
    config.autoload_lib(ignore: nil)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # secret_key_base is not used by Rails API, as there are no sessions
    config.secret_key_base = "blipblapblup"

    # disable ActiveJob logging, as it is very verbose at log level INFO
    config.active_job.logger = Logger.new(nil)

    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Logstash.new
    config.lograge.logger = LogStashLogger.new(type: :stdout)
    config.logger = config.lograge.logger ## LogStashLogger needs to be pass to rails logger, see roidrage/lograge#26
    config.log_level = ENV["LOG_LEVEL"].to_sym ## Log level in a config level configuration

    config.lograge.ignore_actions = %w[
      HeartbeatController#index
      IndexController#index
    ]
    config.lograge.ignore_custom = lambda do |event|
      event.payload.inspect.length > 100_000
    end
    config.lograge.base_controller_class = "ActionController::API"

    config.lograge.custom_options = lambda do |event|
      # Retrieves trace information for current thread
      correlation = Datadog::Tracing.correlation

      exceptions = %w[controller action format id]

      {
        dd: {
          env: correlation.env,
          service: correlation.service,
          version: correlation.version,
          trace_id: correlation.trace_id,
          span_id: correlation.span_id,
        },
        ddsource: %w[ruby],
        params: event.payload[:params].except(*exceptions),
        uid: event.payload[:uid],
      }
    end

    # configure caching
    config.cache_store = :mem_cache_store, ENV["MEMCACHE_SERVERS"], { namespace: ENV["APPLICATION"] }

    # raise error with unpermitted parameters
    config.action_controller.action_on_unpermitted_parameters = :log

    config.action_view.sanitized_allowed_tags = %w[
      strong
      em
      b
      i
      code
      pre
      sub
      sup
      br
    ]
    config.action_view.sanitized_allowed_attributes = []

    # make sure all input is UTF-8
    config.middleware.insert 0,
                             Rack::UTF8Sanitizer,
                             additional_content_types: %w[
                               application/vnd.api+json
                               application/xml
                             ]

    # detect bots and crawlers
    config.middleware.use Rack::CrawlerDetect

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # use batch loader
    config.middleware.use BatchLoader::Middleware

    # set Active Job queueing backend
    config.active_job.queue_adapter = ENV["AWS_REGION"] ? :shoryuken : :inline

    # use SQS based on environment or what has been defined
    config.active_job.queue_name_prefix = ENV["SQS_PREFIX"].present? ? ENV["SQS_PREFIX"] : Rails.env

    config.generators { |g| g.fixture_replacement :factory_bot }

    config.paperclip_defaults = {
      storage: :filesystem, url: "/images/members/:filename"
    }

    config.allowed_cors_origins = []

    # https://blog.kiprosh.com/rails-7-1-raises-on-assignment-to-readonly-attributes
    # in the provider, and client model we have the following code: `attr_readonly :symbol`
    # in rails 7.1 the default is to raise an ActiveRecord::ReadonlyAttributeError.
    # by adding in this config we can allow the old behaviour i.e. not persist the change on update.
    # the ideal solution, would be to rework how we use safe_params.
    # have different safe_params for update and create (this is the way).
    config.active_record.raise_on_assign_to_attr_readonly = false
  end
end
