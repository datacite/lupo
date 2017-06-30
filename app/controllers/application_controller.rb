class ApplicationController < ActionController::API
  # include Authenticable
  before_action :authenticate_request, only: [:update, :destroy]

  require 'facets/string/snakecase'

  attr_reader :current_datacentre

  private

  def authenticate_request
    @current_datacentre = AuthorizeApiRequest.call(request.headers).result
    render json: { error: 'Not Authorized' }, status: 401 unless @current_datacentre
  end

end
