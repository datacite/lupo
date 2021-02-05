require 'compressed_requests'

Rails.application.configure do
  config.middleware.insert_before Rack::Head, CompressedRequests
end
