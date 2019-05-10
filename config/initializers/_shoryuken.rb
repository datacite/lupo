# frozen_string_literal: true

Shoryuken.configure_server do |config|
  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Logger.const_get(ENV["LOG_LEVEL"].upcase)
end

Shoryuken.active_job_queue_name_prefixing = true
