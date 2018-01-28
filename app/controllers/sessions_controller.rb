class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]

  def create
    if safe_params[:grant_type] != "password"
      error_response("Wrong grant type.")
    elsif safe_params[:username].blank? || safe_params[:password].blank?
      error_response("Missing username or password.")
    else
      credentials = User.encode_auth_param(username: safe_params[:username], password: safe_params[:password])
      user = User.new(credentials, type: "basic")

      if user.role_id == "anonymous"
        error_response("Wrong username or password.")
      else
        render json: { "access_token" => user.jwt, "expires_in" => 3600 * 24 * 30 }.to_json, status: 200
      end
    end
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
