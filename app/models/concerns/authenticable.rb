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

    def encrypt_password(password)
      Digest::SHA256.hexdigest password + "{" + ENV["SESSION_ENCRYPTED_COOKIE_SALT"] + "}" if password.present?
    end
  end
end
