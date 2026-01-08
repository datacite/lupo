# frozen_string_literal: true

require "aws-sdk-core"

class DatafileController < ApplicationController
  prepend_before_action :authenticate_user!
  before_action :validate_config

  CREDENTIAL_EXPIRY_TIME = 3600

  rescue_from Aws::Errors::MissingCredentialsError, with: :handle_aws_missing_credentials
  rescue_from Aws::STS::Errors::ServiceError, with: :handle_aws_sts_service_error
  rescue_from Seahorse::Client::NetworkingError, with: :handle_aws_networking_error

  # Ensures required environment configuration exists before handling requests.
  # If the config is missing, returns a 500 to the client.
  def validate_config
    return unless ENV["MONTHLY_DATAFILE_BUCKET"].blank? || ENV["MONTHLY_DATAFILE_ACCESS_ROLE"].blank?

    Rails.logger.error(
      "Monthly Data File access missing required configuration " \
      "(bucket_present=#{ENV["MONTHLY_DATAFILE_BUCKET"].present?}, role_present=#{ENV["MONTHLY_DATAFILE_ACCESS_ROLE"].present?})"
    )

    render json: {
      errors: [{ status: "500", title: "Internal Server Error" }]
    }, status: :internal_server_error
  end

  # Factory method to build the AWS STS client.
  # Kept as a method to allow stubbing in request specs.
  def create_sts_client
    Aws::STS::Client.new
  end

  # Requests temporary role credentials from AWS STS for a given user id.
  #
  # Raises:
  # - Aws::STS::Errors::ServiceError
  # - Aws::Errors::MissingCredentialsError
  # - Seahorse::Client::NetworkingError
  def get_role_credentials(user_id)
    client = create_sts_client

    resp = client.assume_role(
      role_arn: ENV["MONTHLY_DATAFILE_ACCESS_ROLE"],
      role_session_name: user_id.to_s,
      duration_seconds: CREDENTIAL_EXPIRY_TIME
    )

    Rails.logger.info(
      "Created temporary credentials to access the monthly data file " \
      "(uid=#{user_id}, assumed_role_id=#{resp.assumed_role_user.assumed_role_id}, expiry=#{resp.credentials.expiration.utc.iso8601})"
    )
    resp.credentials
  end

  # Generates temporary credentials for downloading the monthly data file.
  def create_credentials
    authorize! :read, :access_datafile

    Rails.logger.info(
      "Monthly data file access requested " \
      "(user=#{current_user.name}, uid=#{current_user.uid}, role=#{current_user.role_id}, request_id=#{request.request_id})"
    )

    credentials = get_role_credentials(current_user.uid)

    render json: {
      "bucket" => ENV["MONTHLY_DATAFILE_BUCKET"],
      "access_key_id" => credentials.access_key_id,
      "secret_access_key" => credentials.secret_access_key,
      "session_token" => credentials.session_token,
      "expires_in" => CREDENTIAL_EXPIRY_TIME
    }, status: :ok
  end

  private
    # Handles missing server-side AWS credentials/configuration issues.
    def handle_aws_missing_credentials(error)
      Rails.logger.error(
        "AWS credentials missing while generating monthly datafile STS credentials " \
        "(uid=#{current_user&.uid}, request_id=#{request.request_id}, error=#{error.class}: #{error.message})"
      )

      render json: {
        errors: [{ status: "500", title: "Internal Server Error" }]
      }, status: :internal_server_error
    end

    # Handles STS service errors such as AccessDenied, ExpiredToken, InvalidClientTokenId, etc.
    def handle_aws_sts_service_error(error)
      Rails.logger.warn(
        "AWS STS error while generating monthly datafile STS credentials " \
        "(uid=#{current_user&.uid}, request_id=#{request.request_id}, error=#{error.class}, message=#{error.message})"
      )

      render json: {
        errors: [{ status: "500", title: "Internal Server Error" }]
      }, status: :internal_server_error
    end

    # Handles connectivity/timeout problems to AWS endpoints.
    def handle_aws_networking_error(error)
      Rails.logger.warn(
        "AWS networking error while generating monthly datafile STS credentials " \
        "(uid=#{current_user&.uid}, request_id=#{request.request_id}, error=#{error.class}, message=#{error.message})"
      )

      render json: {
        errors: [{ status: "500", title: "Internal Server Error" }]
      }, status: :internal_server_error
    end
end
