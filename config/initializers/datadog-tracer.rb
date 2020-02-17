# frozen_string_literal: true

Datadog.configure do |c|
  c.enabled Rails.env.production?
  c.use :rails, service_name: "client-api"
end
