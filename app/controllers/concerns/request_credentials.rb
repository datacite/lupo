# frozen_string_literal: true

# Shared Authorization-header credential parsing for REST and MDS controllers.
module RequestCredentials
  extend ActiveSupport::Concern

  # based on https://github.com/nsarno/knock/blob/master/lib/knock/authenticable.rb
  def type_and_credentials_from_request_headers
    request.headers["Authorization"]&.split
  end

  # Build a User from the request Authorization header.
  # Returns nil when credentials are missing.
  # Raises JWT::VerificationError when the token is blacklisted.
  def user_from_request_credentials
    type, credentials = type_and_credentials_from_request_headers
    return if credentials.blank?

    if (ENV["JWT_BLACKLISTED"] || "").split(",").include?(credentials)
      raise JWT::VerificationError
    end

    User.new(credentials, type: type)
  end
end
