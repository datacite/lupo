# frozen_string_literal: true

require "ddtrace"

Datadog.configure do |c|
  # Global
  c.agent.host = "datadog.local"
  c.runtime_metrics.enabled = true
  c.service = "client-api"
  c.env = Rails.env

  # Tracing settings
  c.tracing.enabled = Rails.env.production?
  c.tracing.analytics.enabled = true
  # We disable automatic log injection because it doesn't play nice with our formatter
  c.tracing.log_injection = false

  # Instrumentation
  c.tracing.instrument :rails
  c.tracing.instrument :elasticsearch
  c.tracing.instrument :shoryuken
end
