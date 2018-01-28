class SessionsController < ApplicationController
  def create
    Rails.logger.info safe_params.inspect
    error_response("Wrong grant type.") && return if safe_params[:grant_type] != "password"
    error_response("Missing account or password.") && return if
      safe_params[:username].blank? || safe_params[:username] == "undefined" ||
      safe_params[:password].blank? || safe_params[:password] == "undefined"

    credentials = User.encode_auth_param(username: safe_params[:username], password: safe_params[:password])
    user = User.new(credentials, type: "basic")

    error_response("Wrong account or password.") && return if user.role_id == "anonymous"

    render json: { "access_token" => user.jwt, "expires_in" => 3600 * 24 * 30 }.to_json, status: 200
  end

  private

  def error_response(message)
    status = 400
    Rails.logger.info message
    render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
  end

  def safe_params
    params.permit(:grant_type, :username, :password, :client_id, :client_secret, :format, :controller, :action)
  end
end
