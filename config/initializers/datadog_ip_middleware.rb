# frozen_string_literal: true

module Middleware
  class DatadogIpMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      client_ip = request.headers['X-Forwarded-For'] || request.remote_ip

      Datadog.tracer.trace('rails.request') do |span|
        span.set_tag('http.client_ip', client_ip)
        @app.call(env)
      end
    end
  end
end
