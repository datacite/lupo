require 'ddtrace'

Datadog.configure do |c|
    # Global
    c.agent.host = 'datadog.local'
    c.runtime_metrics.enabled = true
    c.service = 'client-api'
    c.env = Rails.env

    # Tracing settings
    c.tracing.enabled = Rails.env.production?
    c.tracing.analytics.enabled = true

    # Instrumentation
    c.tracing.instrument :rails
    c.tracing.instrument :elasticsearch
    c.tracing.instrument :shoryuken
end
