# frozen_string_literal: true

Datadog.configure do |c|
  c.use :rails, service_name: "client-api"
end
