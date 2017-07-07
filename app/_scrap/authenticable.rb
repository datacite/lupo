module Authenticable
  extend ActiveSupport::Concern

  def initialize(headers = {})
    @headers = headers
  end

  def call(headers = {})
    @headers = headers
    current_user
  end

  private

  attr_reader :headers

  def current_user
    @user ||= User.new(decoded_auth_token) if decoded_auth_token
    @user || nil
  end

  def decoded_auth_token
    @decoded_auth_token ||= JsonWebToken.decode(http_auth_header)
  end

  def http_auth_header
    if headers['Authorization'].present?
      return headers['Authorization'].split(' ').last
    else
      errors.add(:token, 'Missing token')
    end
    nil
  end












end
