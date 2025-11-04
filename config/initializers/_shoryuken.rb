# frozen_string_literal: true

# Shoryuken middleware to capture worker errors and send them on to Sentry.io
module Shoryuken
  module Middleware
    module Server
      class SentryReporter
        def call(_worker_instance, queue, _sqs_msg, body)
          Sentry.with_scope do |scope|
            context_hash = body.is_a?(Hash) ? body : JSON.parse(body)
            # scope.set_tags(job: body["job_class"], queue: queue)
            # scope.set_context(:message, body)
            scope.set_tags(job: context_hash["job_class"], queue: queue)
            scope.set_context(:message, context_hash)
            yield
          end
        rescue StandardError => e
          Sentry.capture_exception(e)
          raise
        end
      end
    end
  end
end

Shoryuken.configure_server do |config|
  config.server_middleware do |chain|
    # remove logging of timing events
    chain.remove Shoryuken::Middleware::Server::Timing
    chain.add Shoryuken::Middleware::Server::SentryReporter
  end
end

Shoryuken.active_job_queue_name_prefixing = true
