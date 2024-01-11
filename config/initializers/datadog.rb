require 'ddtrace'

Datadog.configure do |c|
    # Global
    c.agent.host = 'datadog.local'
    c.runtime_metrics.enabled = true
    c.service = 'client-api'
    c.env = Rails.env

    # Tracing settings
    c.tracing.analytics.enabled = Rails.env.production?

    # Instrumentation
    c.tracing.instrument :rails
    c.tracing.instrument :elasticsearch
    c.tracing.instrument :shoryuken
end
