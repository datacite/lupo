Shoryuken.configure_server do |config|
  logger = Shoryuken::Logging.logger
end

Shoryuken.active_job_queue_name_prefixing = true
