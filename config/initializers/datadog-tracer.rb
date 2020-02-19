# frozen_string_literal: true

Datadog.configure do |c|
  c.use :rails, service_name: "client-api"
  c.tracer hostname: "datadog.local", enabled: Rails.env.production?
end
