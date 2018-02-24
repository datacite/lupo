Shoryuken.configure_server do |config|
  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Logger.const_get(ENV["LOG_LEVEL"].upcase)
end
