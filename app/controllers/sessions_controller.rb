class SessionsController < ApplicationController
  def create
    error_response("Wrong grant type.") && return if safe_params[:grant_type] != "password"
    error_response("Missing username or password.") && return if
      safe_params[:username].blank? || safe_params[:password].blank?

    credentials = User.encode_auth_param(username: safe_params[:username], password: safe_params[:password])
    user = User.new(credentials, type: "basic")

    error_response("Wrong username or password.") && return if user.role_id == "anonymous"

    render json: { "access_token" => user.jwt, "expires_in" => 3600 * 24 * 30 }.to_json, status: 200
  end

  private

  def error_response(message)
    status = 400
    Rails.logger.warn message
    render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
  end

  def safe_params
    params.permit(:grant_type, :username, :password, :client_id, :client_secret, :format)
  end
end
