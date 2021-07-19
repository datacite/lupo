# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0,
#                                                   Rack::Cors,
#                                                   debug: true,
#                                                   logger:
#                                                     (-> { Rails.logger }) do
#   allow do
#     origins Rails.application.config.allowed_cors_origins.deep_dup
#     # origins "*"
#     resource "*",
#              headers: :any,
#              expose: %w[X-Credential-Username X-Anonymous-Consumer],
#              methods: %i[get post put patch delete options head],
#              credentials: true
#   end
# end
