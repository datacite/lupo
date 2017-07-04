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
      payload = JWT.decode token, public_key, true, { :algorithm => 'RS256' }




      puts payload.is_a?(Array)
      puts payload.first["exp"]
      puts payload.is_a?(Hash)
      # puts payload.first

      # check whether token has expired
      return {} unless Time.now.to_i < payload["exp"]

      payload.first
    end
  end
end
