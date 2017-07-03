class ApplicationController < ActionController::API
  include Authenticable

  include ApplicationHelper
  require 'facets/string/snakecase'


  before_action :authenticate_request #, only: [:show, :update, :destroy]


  attr_reader :current_user

  private

  def authenticate_request
    user = call(request.headers)

    # @current_user = call(request.headers).result
    render json: error_message, status: 401, content_type: "application/json" unless user
  end

  def error_message
    { errors: [{ status: 401,
      title: 'Not Authorized' }]
    }
  end

end
