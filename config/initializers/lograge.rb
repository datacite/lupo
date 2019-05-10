# frozen_string_literal: true

require "elasticsearch/rails/lograge"

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.logger = LogStashLogger.new(type: :stdout)

  config.lograge.ignore_actions = ['HeartbeatController#index', 'IndexController#index']
  config.lograge.ignore_custom = lambda do |event|
    event.payload.inspect.length > 100000
  end
  config.lograge.base_controller_class = 'ActionController::API'

  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions),
      uid: event.payload[:uid]
    }
  end
end
