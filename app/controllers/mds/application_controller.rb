# frozen_string_literal: true

module Mds
  # Protocol base: auth challenge, plain-text errors, consumer headers.
  # Domain helpers (lookup/write/mint) are included only on controllers that need them.
  class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include CanCan::ControllerAdditions
    include RequestCredentials

    attr_accessor :current_user

    after_action :set_consumer_header

    # Protocol-facing errors always map to plain-text MDS responses.
    rescue_from Mds::Error do |exception|
      render_mds_error(exception.message, exception.status)
    end

    rescue_from IdentifierError do |exception|
      render_mds_error(exception.message, 400)
    end

    rescue_from CanCan::AccessDenied do |_exception|
      render_mds_error("Access is denied", 403)
    end

    rescue_from CanCan::AuthorizationNotPerformed,
                JWT::DecodeError,
                JWT::VerificationError do |_exception|
      render_mds_error("Bad credentials", 401)
    end

    rescue_from ActiveRecord::RecordNotFound,
                AbstractController::ActionNotFound do |_exception|
      render_mds_error("DOI not found", 404)
    end

    def route_not_found
      render plain: "Resource not found", status: :not_found
    end

    protected
      # MDS-specific challenge and plain-text failure bodies; credentials via RequestCredentials.
      def authenticate_mds_user!
        user = user_from_request_credentials

        if user.nil?
          request_http_basic_authentication(
            Mds.realm,
            "An Authentication object was not found in the SecurityContext",
          )
          return false
        end

        @current_user = user

        if @current_user.blank? || @current_user.errors.present? ||
            @current_user.role_id == "anonymous"
          render_mds_error("Bad credentials", 401)
          return false
        end

        true
      end

      def current_ability
        @current_ability ||= Ability.new(current_user)
      end

      def set_consumer_header
        if current_user&.uid.present?
          response.headers["X-Credential-Username"] = current_user.uid
        else
          response.headers["X-Anonymous-Consumer"] = true
        end
      end

      def render_mds(body = "OK", status: 200, headers: {})
        headers.each { |k, v| response.headers[k] = v }

        if status.to_i == 204
          head :no_content
        else
          render plain: body.to_s, status: status
        end
      end

      def render_mds_error(message, status)
        if status.to_i == 401
          response.headers["WWW-Authenticate"] = "Basic realm=\"#{Mds.realm}\""
          response.headers.delete("X-Credential-Username")
        end

        logger.error "[MDS #{status}]: #{message}"
        render plain: message.to_s, status: status
      end

      # Unexpected framework errors — do not map NoMethodError to 422.
      unless Rails.env.development?
        rescue_from ActionController::RoutingError do |_exception|
          render_mds_error("DOI not found", 404)
        end

        rescue_from ActiveModel::ForbiddenAttributesError,
                    ActionController::UnpermittedParameters,
                    ActionController::ParameterMissing do |exception|
          Sentry.capture_exception(exception)
          render_mds_error(exception.message, 422)
        end

        rescue_from NotImplementedError do |_exception|
          render_mds_error("Not Implemented", 501)
        end
      end
  end
end
