# frozen_string_literal: true

module Mds
  class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include CanCan::ControllerAdditions
    include Bolognese::DoiUtils
    include Bolognese::Utils

    attr_accessor :current_user

    after_action :set_consumer_header

    def route_not_found
      render plain: "Resource not found", status: :not_found
    end

    protected

    # Authenticate via HTTP Basic (classic MDS) or Bearer token.
    def authenticate_mds_user!
      type, credentials = type_and_credentials_from_request_headers

      if credentials.blank?
        request_http_basic_authentication(Mds.realm, "An Authentication object was not found in the SecurityContext")
        return false
      end

      if type.to_s.casecmp("basic").zero?
        @current_user = User.new(credentials, type: "basic")
      else
        # Bearer / raw JWT — same path as REST API
        @current_user = User.new(credentials)
      end

      if @current_user.blank? || @current_user.errors.present? || @current_user.role_id == "anonymous"
        response.headers["WWW-Authenticate"] = "Basic realm=\"#{Mds.realm}\""
        response.headers.delete("X-Credential-Username")
        render plain: "Bad credentials", status: :unauthorized
        return false
      end

      true
    end

    def current_ability
      @current_ability ||= Ability.new(current_user)
    end

    def type_and_credentials_from_request_headers
      header = request.headers["Authorization"]
      return [nil, nil] if header.blank?

      type, credentials = header.split(" ", 2)
      return [nil, nil] if credentials.blank?

      [type, credentials]
    end

    def set_consumer_header
      if current_user&.uid.present?
        response.headers["X-Credential-Username"] = current_user.uid
      else
        response.headers["X-Anonymous-Consumer"] = true
      end
    end

    def client_symbol
      (current_user.client_id.presence || current_user.uid).to_s
    end

    unless Rails.env.development?
      rescue_from(*RESCUABLE_EXCEPTIONS, IdentifierError) do |exception|
        status =
          case exception.class.to_s
          when "CanCan::AuthorizationNotPerformed", "JWT::DecodeError", "JWT::VerificationError"
            401
          when "CanCan::AccessDenied"
            403
          when "ActionController::RoutingError", "AbstractController::ActionNotFound",
               "ActiveRecord::RecordNotFound"
            404
          when "ActiveModel::ForbiddenAttributesError", "ActionController::UnpermittedParameters",
               "NoMethodError"
            422
          when "NotImplementedError"
            501
          when "IdentifierError"
            400
          else
            400
          end

        if status == 401
          response.headers["WWW-Authenticate"] = "Basic realm=\"#{Mds.realm}\""
          response.headers.delete("X-Credential-Username")
          message = "Bad credentials"
        elsif status == 403
          message = "Access is denied"
        elsif status == 404
          message = "DOI not found"
        elsif status == 501
          message = "Not Implemented"
        else
          Sentry.capture_exception(exception) unless exception.class.to_s == "IdentifierError"
          message = exception.message
        end

        logger.error "[MDS #{status}]: #{message}"
        render plain: message, status: status
      end
    end
  end
end
