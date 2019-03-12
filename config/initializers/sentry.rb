Raven.configure do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.release = "lupo:" + Lupo::Application::VERSION
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # ignore 502 and 503 from Elasticsearch
  config.excluded_exceptions += ['Elasticsearch::Transport::Transport::Errors::BadGateway', 'Elasticsearch::Transport::Transport::Errors::ServiceUnavailable']
end