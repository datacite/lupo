module Authenticable
  extend ActiveSupport::Concern

  require 'jwt'
  require "base64"

  included do
    # encode JWT token using SHA-256 hash algorithm
    def encode_token(payload)
      return nil if payload.blank?
      
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, 'RS256')
    rescue OpenSSL::PKey::RSAError => e
      logger = Logger.new(STDOUT)
      logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # use only for testing, as we don't have private key for JWT encoded by AWS ALB
    def encode_alb_token(payload)
      return nil if payload.blank? || !Rails.env.test?
      
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey.read(File.read(Rails.root.join("spec", "fixtures", "certs", "ec256-private.pem").to_s))
      JWT.encode(payload, private_key, 'ES256')
    rescue OpenSSL::PKey::ECError => e
      logger = Logger.new(STDOUT)
      logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # decode JWT token using SHA-256 hash algorithm
    def decode_token(token)
      logger = Logger.new(STDOUT)

      public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
      payload = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first

      # check whether token has expired
      fail JWT::ExpiredSignature, "The token has expired." unless Time.now.to_i < payload["exp"].to_i

      payload
    rescue JWT::ExpiredSignature => error
      logger.error "JWT::ExpiredSignature: " + error.message + " for " + token
      return { errors: "The token has expired." }
    rescue JWT::DecodeError => error
      logger.error "JWT::DecodeError: " + error.message + " for " + token
      return { errors: "The token could not be decoded." }
    rescue OpenSSL::PKey::RSAError => error
      public_key = ENV['JWT_PUBLIC_KEY'].presence || "nil"
      logger.error "OpenSSL::PKey::RSAError: " + error.message + " for " + public_key
      return { errors: "An error occured." }
    end

    # decode JWT token from AWS ALB using SHA-256 hash algorithm
    def decode_alb_token(token)
      logger = Logger.new(STDOUT)

      if Rails.env.test?
        public_key = OpenSSL::PKey.read(File.read(Rails.root.join("spec", "fixtures", "certs", "ec256-public.pem").to_s))
      else
        header = JSON.parse(urlsafe_decode64(token.split(".").first))
        kid = header["kid"]
        public_key = cached_alb_public_key(kid)
      end
      
      payload = (JWT.decode token, public_key, true, { algorithm: 'ES256' }).first

      fail NoMethodError unless payload.is_a?(Hash)

      # check whether token has expired
      fail JWT::ExpiredSignature, "The token has expired." unless Time.now.to_i < payload["exp"].to_i
      
      payload
    rescue NoMethodError => error
      logger.error "NoMethodError: " + payload.inspect
      return { errors: "The token could not be decoded." }
    rescue JWT::ExpiredSignature => error
      logger.error "JWT::ExpiredSignature: " + error.message + " for " + token
      return { errors: "The token has expired." }
    rescue JWT::DecodeError => error
      logger.error "JWT::DecodeError: " + error.message + " for " + token.to_s
      return { errors: "The token could not be decoded." }
    rescue OpenSSL::PKey::RSAError, OpenSSL::PKey::ECError => error
      # ecdsa_public = ENV['ALB_PUBLIC_KEY'].presence || "nil"
      logger.error "OpenSSL::PKey::RSAError: " + error.message + " for " + ecdsa_public
      return { errors: "An error occured." }
    end

    # basic auth
    def encode_auth_param(username: nil, password: nil)
      return nil unless username.present? && password.present?

      ::Base64.strict_encode64("#{username}:#{password}")
    end

    # basic auth
    def decode_auth_param(username: nil, password: nil)
      return {} unless username.present? && password.present?

      if username.include?(".")
        user = Client.where(symbol: username.upcase).first
      else
        user = Provider.unscoped.where(symbol: username.upcase).first
      end

      return {} unless user && secure_compare(user.password, encrypt_password_sha256(password))

      uid = username.downcase

      get_payload(uid: uid, user: user, password: password.to_s)
    end

    def get_payload(uid: nil, user: nil, password: nil)
      roles = { 
        "ROLE_ADMIN"                => "staff_admin",
        "ROLE_DATACENTRE"           => "client_admin",
        "ROLE_ALLOCATOR"            => "provider_admin",
        "ROLE_CONSORTIUM"           => "provider_admin",
        "ROLE_CONSORTIUM_ORGANIZATION" => "provider_admin",
        "ROLE_CONTRACTUAL_PROVIDER" => "provider_admin",
        "ROLE_FOR_PROFIT_PROVIDER"  => "provider_admin",
        "ROLE_REGISTRATION_AGENCY"  => "provider_admin"
       }
      payload = {
        "uid" => uid,
        "role_id" => roles.fetch(user.role_name, "user"),
        "name" => user.name,
        "email" => user.contact_email
      }

      # we only need password for clients registering DOIs in the handle system
      if uid.include? "."
        payload.merge!({
          "provider_id" => uid.split(".", 2).first,
          "client_id" => uid,
          "password" => password
        })
      elsif uid != "admin"
        payload.merge!({
          "provider_id" => uid
        })
      end

      payload
    end

    # constant-time comparison algorithm to prevent timing attacks
    # from Devise
    def secure_compare(a, b)
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize
      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end

  module ClassMethods
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      return nil if payload.blank?

      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, 'RS256')
    rescue OpenSSL::PKey::RSAError => e
      logger = Logger.new(STDOUT)
      logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # encode token using ECDSA with P-256 and SHA-256
    # use this only for testing as private key is publicly available from ruby-jwt gem
    def encode_alb_token(payload)
      return nil if payload.blank? || !Rails.env.test?
      private_key = OpenSSL::PKey.read(File.read(Rails.root.join("spec", "fixtures", "certs", "ec256-private.pem").to_s))
      JWT.encode(payload, private_key, 'ES256')
    rescue OpenSSL::PKey::ECError => e
      logger = Logger.new(STDOUT)
      logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # basic auth
    def encode_auth_param(username: nil, password: nil)
      return nil unless username.present? && password.present?

      ::Base64.strict_encode64("#{username}:#{password}")
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
        password: attributes.fetch(:password, nil),
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30)
      }.compact

      encode_token(payload)
    end

    def generate_alb_token(attributes={})
      payload = {
        uid:  attributes.fetch(:uid, "0000-0001-5489-3594"),
        preferred_username: attributes.fetch(:preferred_username, "0000-0001-5489-3594@orcid.org"),
        name: attributes.fetch(:name, "Josiah Carberry"),
        email: attributes.fetch(:email, nil),
        provider_id: attributes.fetch(:provider_id, nil),
        client_id: attributes.fetch(:client_id, nil),
        role_id: attributes.fetch(:role_id, "user"),
        password: attributes.fetch(:password, nil),
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30)
      }.compact

      encode_alb_token(payload)
    end

    def get_payload(uid: nil, user: nil, password: nil)
      roles = { 
        "ROLE_ADMIN"                => "staff_admin",
        "ROLE_DATACENTRE"           => "client_admin",
        "ROLE_ALLOCATOR"            => "provider_admin",
        "ROLE_CONSORTIUM"      => "provider_admin",
        "ROLE_CONTRACTUAL_PROVIDER" => "provider_admin",
        "ROLE_FOR_PROFIT_PROVIDER"  => "provider_admin"
       }
      payload = {
        "uid" => uid,
        "role_id" => roles.fetch(user.role_name, "user"),
        "name" => user.name,
        "email" => user.contact_email
      }

      # we only need password for clients registering DOIs in the handle system
      if uid.include? "."
        payload.merge!({
          "provider_id" => uid.split(".", 2).first,
          "client_id" => uid,
          "password" => password
        })
      elsif uid != "admin"
        payload.merge!({
          "provider_id" => uid
        })
      end

      payload
    end
  end
end
