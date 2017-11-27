module Authenticable
  extend ActiveSupport::Concern

  require 'jwt'

  included do
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, 'RS256')
    end

    # decode token using SHA-256 hash algorithm
    def decode_token(token)
      public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
      payload = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first

      # check whether token has expired
      return {} unless Time.now.to_i < payload["exp"]

      payload
    rescue JWT::DecodeError => error
      Rails.logger.error "JWT::DecodeError: " + error.message + " for " + token
      return {}
    rescue OpenSSL::PKey::RSAError => error
      public_key = ENV['JWT_PUBLIC_KEY'].presence || "nil"
      Rails.logger.error "OpenSSL::PKey::RSAError: " + error.message + " for " + public_key
      return {}
    end
  end

  module ClassMethods
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, 'RS256')
    end

    # generate JWT token
    def generate_token(attributes={})
      payload = {
        uid:  attributes.fetch(:uid, "0000-0001-5489-3594"),
        name: attributes.fetch(:name, "Josiah Carberry"),
        email: attributes.fetch(:email, nil),
        provider_id: attributes.fetch(:provider_id, nil),
        client_id: attributes.fetch(:client_id, nil),
        role_id: attributes.fetch(:role_id, "staff_admin"),
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30)
      }.compact

      encode_token(payload)
    end
  end
end
