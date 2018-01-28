class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]

  def create
    if safe_params[:grant_type] != "password"
      message = "Wrong grant type."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    elsif safe_params[:username].blank? || safe_params[:password].blank?
      message = "Missing username or password."
      status = 400
      Rails.logger.warn message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
    else
      credentials = User.encode_auth_param(username: safe_params[:username], password: safe_params[:password])
      Rails.logger.warn credentials
      user = User.new(credentials, type: "basic")

      if user.role_id == "anonymous"
        message = "Wrong username or password."
        status = 400
        Rails.logger.warn message
        render json: { errors: [{ status: status.to_s, title: message }] }.to_json, status: status
      else
        @current_user = user
        render json: { "access_token" => user.jwt, "expires_in" => 3600 * 24 * 30 }.to_json, status: 200
      end
    end
  end

  private

  def safe_params
    params.permit(:grant_type, :username, :password, :client_id, :client_secret, :format)
  end
end
