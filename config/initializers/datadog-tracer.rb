# frozen_string_literal: true

Datadog.configure do |c|
  c.tracer hostname: "datadog.local", enabled: Rails.env.production?, env: Rails.env
  c.use :rails, service_name: "client-api"
  c.use :elasticsearch
  c.use :active_record, analytics_enabled: false
  c.use :graphql, schemas: [LupoSchema]
  c.analytics_enabled = true
end
