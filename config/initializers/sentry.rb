# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  
  # Enable Rails integration
  config.rails.report_rescued_exceptions = true
  
  # Set environment
  config.environment = Rails.env
  config.enabled_environments = %w[stage production]
  
  # Set release version
  config.release = "lupo:" + Lupo::Application::VERSION
  
  # Filter sensitive parameters
  config.send_default_pii = false
  
  # Use Rails parameter filtering (sentry-rails handles this automatically)
  # No need to manually configure - sentry-rails will respect Rails.application.config.filter_parameters
  
  # Ignore 502, 503 and 504 from Elasticsearch
  config.excluded_exceptions += %w[
    Elasticsearch::Transport::Transport::Errors::BadGateway
    Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
    Elasticsearch::Transport::Transport::Errors::GatewayTimeout
  ]
  
  # Performance monitoring (optional - adjust sample_rate as needed)
  # Uncomment to enable APM - monitor request performance, database queries, etc.
  # config.traces_sample_rate = 0.1  # 10% of requests
  
  # Sample rate for error events (reduce noise if needed)
  # Uncomment if you're still hitting rate limits after upgrade
  # config.sample_rate = 0.8  # Send 80% of errors
  
  # Before send callback - for custom filtering/scrubbing
  # config.before_send = lambda do |event, hint|
  #   # Return nil to drop the event, or modify and return it
  #   event
  # end
  
  # Async error sending (better performance, uses background threads)
  config.background_worker_threads = 5
  
  # Logger configuration - uses LogStashLogger (structured JSON logging)
  # Rails.logger and Rails.application.config.lograge.logger are the same instance
  config.logger = Rails.logger
end
