# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include Authenticable
  include CanCan::ControllerAdditions
  include ErrorSerializable
  require "facets/string/snakecase"

  # include helper module for caching infrequently changing resources
  include Cacheable
  include Facetable

  # include helper module for generating random DOI suffixes
  include Helpable

  # include helper module for pagination
  include Paginatable

  # include helper module for sparse fieldsets
  include Fieldable

  attr_accessor :current_user

  # pass ability into serializer
  serialization_scope :current_ability

  before_action :default_format_json, :transform_params, :set_raven_context
  after_action :set_jsonp_format, :set_consumer_header

  # from https://github.com/spree/spree/blob/master/api/app/controllers/spree/api/base_controller.rb
  def set_jsonp_format
    if params[:callback] && request.get?
      self.response_body = "#{params[:callback]}(#{response.body})"
      headers["Content-Type"] = "application/javascript"
    end
  end

  def detect_crawler
    #### Crawlers shouldn't be making queires
    if request.is_crawler? && params[:query].present?
      render json: {}, status: :not_found
    end
  end

  def set_consumer_header
    if current_user
      response.headers["X-Credential-Username"] = current_user.uid
    else
      response.headers["X-Anonymous-Consumer"] = true
    end
  end

  # convert parameters with hyphen to parameters with underscore.
  # deep_transform_keys has been removed in Rails 5.1
  # https://stackoverflow.com/questions/35812277/fields-parameters-with-hyphen-in-ruby-on-rails
  def transform_params
    params.transform_keys! { |key| key.tr("-", "_") }
  end

  def default_format_json
    request.format = :json if request.format.html?
  end

  def authenticate_user_with_basic_auth!
    @user = authenticate_user!

    request_http_basic_authentication(ENV["REALM"]) if !@user

    @user
  end

  def authenticate_user!
    Rails.logger.info("orcid_claim: authenticate_user!")

    type, credentials = type_and_credentials_from_request_headers

    Rails.logger.info("orcid_claim: type: #{type}")
    Rails.logger.info("orcid_claim: credentials: #{credentials.inspect}")
    Rails.logger.info("orcid_claim: credentials_blank?: #{credentials.blank?}")

    return false if credentials.blank?

    if (ENV["JWT_BLACKLISTED"] || "").split(",").include?(credentials)
      raise JWT::VerificationError
    end

    @current_user = User.new(credentials, type: type)

    Rails.logger.info("orcid_claim: current_user: #{@current_user.inspect}")

    fail CanCan::AuthorizationNotPerformed if @current_user.errors.present?

    @current_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # based on https://github.com/nsarno/knock/blob/master/lib/knock/authenticable.rb
  def type_and_credentials_from_request_headers
    Rails.logger.info("orcid_claim: inside credentials read")
    request.headers.each do |key, value|
      puts"#{key}: #{value}"
    end
    request.headers["Authorization"]&.split
  end

  def authenticated_user
    current_user.try(:uid)
  end

  unless Rails.env.development?
    rescue_from(*RESCUABLE_EXCEPTIONS) do |exception|
      status =
        case exception.class.to_s
        when "CanCan::AuthorizationNotPerformed", "JWT::DecodeError",
             "JWT::VerificationError"
          401
        when "CanCan::AccessDenied"
          403
        when "ActiveRecord::RecordNotFound", "AbstractController::ActionNotFound",
             "ActionController::RoutingError"
          404
        when "ActionController::UnknownFormat"
          406
        when "ActiveRecord::RecordNotUnique"
          409
        when "ActiveModel::ForbiddenAttributesError", "ActionController::ParameterMissing",
             "ActionController::UnpermittedParameters", "ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument"
          422
        when "ActionController::BadRequest"
          400
        when "SocketError"
          500
        else
          400
        end

      if status == 401
        message = "Bad credentials."
      elsif status == 403 && current_user.try(:uid)
        message = "You are not authorized to access this resource."
      elsif status == 403
        status = 401
        message = "Bad credentials."
      elsif status == 404
        message = "The resource you are looking for doesn't exist."
      elsif status == 406
        message = "The content type is not recognized."
      elsif status == 409
        message = "The resource already exists."
      elsif %w[
        JSON::ParserError
        Nokogiri::XML::SyntaxError
        ActionDispatch::Http::Parameters::ParseError
        ActionController::BadRequest
      ].include?(exception.class.to_s)
        message = exception.message
      else
        Raven.capture_exception(exception)

        message = exception.message
      end

      render json: {
        errors: [{ status: status.to_s, title: message }],
      }.to_json,
             status: status
    end
  end

  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = previous_value
  end

  protected
    def is_admin_or_staff?
      current_user&.is_admin_or_staff? ? 1 : 0
    end

  private
    def append_info_to_payload(payload)
      super
      payload[:uid] = current_user.uid.downcase if current_user.try(:uid)
    end

    def set_raven_context
      if current_user.try(:uid)
        Raven.user_context(
          email: current_user.email, id: current_user.uid, ip_address: request.ip,
        )
      else
        Raven.user_context(ip_address: request.ip)
      end
    end
end
