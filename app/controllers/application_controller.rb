class ApplicationController < ActionController::API
  include Authenticable
  include CanCan::ControllerAdditions
  include ErrorSerializable
  require 'facets/string/snakecase'

  # include helper module for caching infrequently changing resources
  include Cacheable
  include Facetable

  # include helper module for generating random DOI suffixes
  include Helpable

  attr_accessor :current_user

  # pass ability into serializer
  serialization_scope :current_ability

  before_bugsnag_notify :add_user_info_to_bugsnag

  before_action :default_format_jsonapi, :transform_params
  after_action :set_jsonp_format, :set_consumer_header

  # from https://github.com/spree/spree/blob/master/api/app/controllers/spree/api/base_controller.rb
  def set_jsonp_format
    if params[:callback] && request.get?
      self.response_body = "#{params[:callback]}(#{response.body})"
      headers["Content-Type"] = 'application/javascript'
    end
  end

  def set_consumer_header
    if current_user
      response.headers['X-Credential-Username'] = current_user.uid
    else
      response.headers['X-Anonymous-Consumer'] = true
    end
  end

  # convert parameters with hyphen to parameters with underscore.
  # deep_transform_keys has been removed in Rails 5.1
  # https://stackoverflow.com/questions/35812277/fields-parameters-with-hyphen-in-ruby-on-rails
  def transform_params
    params.transform_keys! { |key| key.tr('-', '_') }
  end

  def default_format_jsonapi
    request.format = :jsonapi if request.format.html?
  end

  def authenticate_user!
    type, credentials = type_and_credentials_from_request_headers
    return false unless credentials.present?

    @current_user = User.new(credentials, type: type)
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # based on https://github.com/nsarno/knock/blob/master/lib/knock/authenticable.rb
  def type_and_credentials_from_request_headers
    unless request.headers['Authorization'].nil?
      request.headers['Authorization'].split
    end
  end

  unless Rails.env.development?
    rescue_from *RESCUABLE_EXCEPTIONS do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied", "JWT::DecodeError" then 401
               when "ActiveRecord::RecordNotFound", "AbstractController::ActionNotFound", "ActionController::RoutingError" then 404
               when "ActionController::UnknownFormat" then 406
               when "ActiveModel::ForbiddenAttributesError", "ActionController::ParameterMissing", "ActionController::UnpermittedParameters" then 422
               else 400
               end

      if status == 404
        message = "The resource you are looking for doesn't exist."
      elsif status == 401
        message = "You are not authorized to access this resource."
      elsif status == 406
        message = "The content type is not recognized."
      else
        Bugsnag.notify(exception)

        message = exception.message
      end

      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    end
  end

  protected

  def is_admin_or_staff?
    current_user && current_user.is_admin_or_staff? ? 1 : 0
  end

  private

  def add_user_info_to_bugsnag(report)
    return nil unless current_user.present?
    
    report.user = {
      email: current_user.email,
      name: current_user.name,
      id: current_user.id
    }
  end
end
