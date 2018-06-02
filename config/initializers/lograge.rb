Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.logger = ActiveSupport::Logger.new(STDOUT)

  config.lograge.ignore_actions = ['HeartbeatController#index', 'IndexController#index']
  config.lograge.base_controller_class = 'ActionController::API'
  config.log_level = ENV['LOG_LEVEL'].to_sym
end
