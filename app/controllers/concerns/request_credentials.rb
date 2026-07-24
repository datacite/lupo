# frozen_string_literal: true

module RequestCredentials
  extend ActiveSupport::Concern

  # based on https://github.com/nsarno/knock/blob/master/lib/knock/authenticable.rb
  def type_and_credentials_from_request_headers
    request.headers["Authorization"]&.split
  end

  def user_from_request_credentials
    type, credentials = type_and_credentials_from_request_headers
    return if credentials.blank?

    if (ENV["JWT_BLACKLISTED"] || "").split(",").include?(credentials)
      raise JWT::VerificationError
    end

    User.new(credentials, type: type)
  end

  def authenticate_request!
    @current_user = user_from_request_credentials
    return false if @current_user.nil?

    fail CanCan::AuthorizationNotPerformed if @current_user.errors.present?

    tag_api_key_observability!
    @current_user
  end

  def tag_api_key_observability!
    return unless @current_user.try(:api_key_authenticated?)
    return unless defined?(Sentry)

    Sentry.set_tags(
      auth_method: @current_user.auth_method,
      api_key_prefix: @current_user.api_key_prefix,
    )
  end
end
