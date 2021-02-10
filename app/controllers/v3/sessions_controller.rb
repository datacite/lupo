# frozen_string_literal: true

class V3::SessionsController < ApplicationController
  def create_token
    if safe_params[:grant_type] != "password"
      error_response("Wrong grant type.") && return
    end
    if safe_params[:username].blank? || safe_params[:username] == "undefined" ||
        safe_params[:password].blank? ||
        safe_params[:password] == "undefined"
      error_response("Missing account ID or password.") && return
    end

    credentials =
      User.encode_auth_param(
        username: safe_params[:username], password: safe_params[:password],
      )
    user = User.new(credentials, type: "basic")

    error_response(user.errors) && return if user.errors.present?
    if user.role_id == "anonymous"
      error_response("Wrong account ID or password.") && return
    end

    render json: {
      "access_token" => user.jwt, "expires_in" => 3_600 * 24 * 30
    }.to_json,
           status: :ok
  end

  def create_oidc_token
    if safe_params[:token].blank? || safe_params[:token] == "undefined"
      error_response("Missing token.") && return
    end

    user = User.new(safe_params[:token], type: "oidc")
    error_response(user.errors) && return if user.errors.present?

    render json: {
      "access_token" => user.jwt, "expires_in" => 3_600 * 24 * 30
    }.to_json,
           status: :ok
  end

  def reset
    if safe_params[:username].blank?
      message = "Missing account ID."
      status = :ok
    else
      response = User.reset(safe_params[:username])
      if response.present?
        message = response[:message]
        status = response[:status]
      else
        message = "Account not found."
        status = :ok
      end
    end

    render json: { "message" => message }.to_json, status: status
  end

  private
    def error_response(message)
      status = 400
      logger.error message
      render json: { errors: [{ status: status.to_s, title: message }] }.to_json,
             status: status
    end

    def safe_params
      params.permit(
        :grant_type,
        :username,
        :password,
        :token,
        :client_id,
        :client_secret,
        :refresh_token,
        :session,
        :format,
        :controller,
        :action,
      )
    end
end
