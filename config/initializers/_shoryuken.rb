# frozen_string_literal: true

# Shoryuken middleware to capture worker errors and send them on to Sentry.io
module Shoryuken
  module Middleware
    module Server
      class RavenReporter
        def call(worker_instance, queue, sqs_msg, body)
          tags = { job: body['job_class'], queue: queue }
          context = { message: body }
          Raven.capture(tags: tags, extra: context) do
            yield
          end
        end
      end
    end
  end
end

Shoryuken.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Shoryuken::Middleware::Server::RavenReporter
  end

  Rails.logger = Shoryuken::Logging.logger
  Rails.logger.level = Logger.const_get(ENV["LOG_LEVEL"].upcase)
end

Shoryuken.active_job_queue_name_prefixing = true
