require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"
require 'syslog/logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

env_file = File.expand_path("../../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

module Lupo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app/models/concerns')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # secret_key_base is not used by Rails API, as there are no sessions
    config.secret_key_base = 'blipblapblup'

    # See everything in the log (default is :info)
    log_level = ENV["LOG_LEVEL"] ? ENV["LOG_LEVEL"].to_sym : :info
    config.log_level = log_level

    # Use a different logger for distributed setups
    config.lograge.enabled = true
    config.logger = Syslog::Logger.new(ENV['APPLICATION'])

    # add elasticsearch instrumentation to logs
    require 'elasticsearch/rails/lograge'

    # raise error with unpermitted parameters
    config.action_controller.action_on_unpermitted_parameters = :raise

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # set Active Job queueing backend
    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.fixture_replacement :factory_girl
    end
  end
end
