# frozen_string_literal: true

require "./lib/middleware/compressed_requests"

Rails.application.configure do
  config.middleware.insert_before Rack::Head, Middleware::CompressedRequests

  config.middleware.use Middleware::DatadogIpMiddleware
end
