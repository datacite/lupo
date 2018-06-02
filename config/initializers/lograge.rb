Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.logger = LogStashLogger.new(type: :stdout)

  config.lograge.ignore_actions = ['HeartbeatController#index', 'IndexController#index']
  config.lograge.base_controller_class = 'ActionController::API'
  config.log_level = ENV['LOG_LEVEL'].to_sym

  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions)
    }
  end
end
