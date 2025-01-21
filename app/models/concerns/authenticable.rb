# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  require "jwt"
  require "base64"

  included do
    # encode JWT token using SHA-256 hash algorithm
    def encode_token(payload)
      return nil if payload.blank?

      # replace newline characters with actual newlines
      private_key =
        OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, "RS256")
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # use only for testing, as we don't have private key for JWT encoded by AWS ALB
    def encode_alb_token(payload)
      return nil if payload.blank? || !Rails.env.test?

      # replace newline characters with actual newlines
      private_key =
        OpenSSL::PKey.read(
          File.read(
            Rails.root.join("spec", "fixtures", "certs", "ec256-private.pem").
              to_s,
          ),
        )
      JWT.encode(payload, private_key, "ES256")
    rescue OpenSSL::PKey::ECError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # use only for testing, as we don't have private key for JWT encoded by Globus
    def encode_globus_token(payload)
      return nil if payload.blank? || !Rails.env.test?

      # replace newline characters with actual newlines
      private_key =
        OpenSSL::PKey.read(
          File.read(
            Rails.root.join("spec", "fixtures", "certs", "ec512-private.pem").
              to_s,
          ),
        )
      JWT.encode(payload, private_key, "RS512")
    rescue OpenSSL::PKey::ECError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # decode JWT token. Check whether it is a DataCite or Globus JWT via the JWT header
    # DataCite uses RS256, Globus uses RS512
    def decode_token(token)
      # check that JWT has header, payload and secret, separated by dot
      token_parts = token.to_s.split(".")
      raise JWT::DecodeError if token_parts.length != 3

      # decode token
      header = JSON.parse(Base64.urlsafe_decode64(token_parts.first))
      case header["alg"]
      when "RS256"
        # DataCite JWT
        public_key =
          OpenSSL::PKey::RSA.new(ENV["JWT_PUBLIC_KEY"].to_s.gsub('\n', "\n"))
        payload = (JWT.decode token, public_key, true, algorithm: "RS256").first
      when "RS512"
        # Globus JWT
        public_key =
          OpenSSL::PKey::RSA.new(
            cached_globus_public_key.fetch("n", nil).to_s.gsub('\n', "\n"),
          )
        payload = (JWT.decode token, public_key, true, algorithm: "RS512").first
      else
        raise JWT::DecodeError, "Algorithm #{header['alg']} is not supported."
      end

      # check whether token has expired
      unless Time.now.to_i < payload["exp"].to_i
        fail JWT::ExpiredSignature, "The token has expired."
      end

      payload
    rescue JWT::ExpiredSignature => e
      Rails.logger.error "JWT::ExpiredSignature: " + e.message + " for " + token
      { errors: "The token has expired." }
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT::DecodeError: " + e.message + " for " + token
      { errors: "The token could not be decoded." }
    rescue OpenSSL::PKey::RSAError => e
      public_key = ENV["JWT_PUBLIC_KEY"].presence || "nil"
      Rails.logger.error "OpenSSL::PKey::RSAError: " + e.message + " for " +
        public_key
      { errors: "An error occured." }
    end

    # decode JWT token from AWS ALB using SHA-256 hash algorithm
    def decode_alb_token(token)
      if Rails.env.test?
        public_key =
          OpenSSL::PKey.read(
            File.read(
              Rails.root.join("spec", "fixtures", "certs", "ec256-public.pem").
                to_s,
            ),
          )
      else
        header = JSON.parse(Base64.urlsafe_decode64(token.split(".").first))
        kid = header["kid"]
        public_key_string = cached_alb_public_key(kid)
        public_key = OpenSSL::PKey::EC.new(public_key_string.gsub('\n', "\n"))
      end

      payload = (JWT.decode token, public_key, true, algorithm: "ES256").first
      fail NoMethodError, "Payload is not a hash" unless payload.is_a?(Hash)

      # check whether token has expired
      unless Time.now.to_i < payload["exp"].to_i
        fail JWT::ExpiredSignature, "The token has expired."
      end

      payload
    rescue NoMethodError => e
      Rails.logger.error "NoMethodError: " + e.message + " for " + token
      { errors: "The token could not be decoded." }
    rescue JWT::ExpiredSignature => e
      Rails.logger.error "JWT::ExpiredSignature: " + e.message + " for " + token
      { errors: "The token has expired." }
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT::DecodeError: " + e.message + " for " + token.to_s
      { errors: "The token could not be decoded." }
    rescue OpenSSL::PKey::ECError => e
      Rails.logger.error "OpenSSL::PKey::RSAError: " + e.message
      { errors: "An error occured." }
    end

    # basic auth
    def encode_auth_param(username: nil, password: nil)
      return nil unless username.present? && password.present?

      ::Base64.strict_encode64("#{username}:#{password}")
    end

    # basic auth
    def decode_auth_param(username: nil, password: nil)
      return {} unless username.present? && password.present?

      user =
        if username.include?(".")
          Client.where(symbol: username.upcase).first
        else
          Provider.unscoped.where(symbol: username.upcase).first
        end

      unless user &&
          secure_compare(user.password, encrypt_password_sha256(password))
        return {}
      end

      uid = username.downcase

      get_payload(uid: uid, user: user, password: password.to_s)
    end

    def get_payload(uid: nil, user: nil, password: nil)
      roles = {
        "ROLE_ADMIN" => "staff_admin",
        "ROLE_DEV" => "staff_admin",
        "ROLE_DATACENTRE" => "client_admin",
        "ROLE_ALLOCATOR" => "provider_admin",
        "ROLE_MEMBER" => "provider_admin",
        "ROLE_CONSORTIUM" => "consortium_admin",
        "ROLE_CONSORTIUM_ORGANIZATION" => "provider_admin",
        "ROLE_CONTRACTUAL_PROVIDER" => "provider_admin",
        "ROLE_FOR_PROFIT_PROVIDER" => "provider_admin",
      }
      payload = {
        "uid" => uid,
        "role_id" => roles.fetch(user.role_name, "user"),
        "name" => user.name,
        "email" => user.system_email,
      }

      # we only need password for clients registering DOIs in the handle system
      if uid.include? "."
        payload["provider_id"] = user.provider_id
        payload["client_id"] = uid
      elsif uid != "admin"
        payload["provider_id"] = uid
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

    # check user permissions
    def not_allowed_by_doi_and_user(doi: nil, user: nil)
      return true if doi.blank?
      return false if doi.aasm_state == "findable"
      return true if user.blank?
      return false if %w[staff_admin staff_user].include?(user.role_id)
      if %w[consortium_admin].include?(user.role_id) &&
          user.provider_id.present? &&
          user.provider_id.upcase == doi.provider.consortium_id
        return false
      end
      if %w[provider_admin provider_user].include?(user.role_id) &&
          user.provider_id.present? &&
          user.provider_id == doi.provider_id
        return false
      end
      if %w[client_admin client_user user temporary].include?(user.role_id) &&
          user.client_id.present? &&
          user.client_id == doi.client_id
        return false
      end

      true
    end
  end

  module ClassMethods
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      return nil if payload.blank?

      # replace newline characters with actual newlines
      private_key =
        OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, "RS256")
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # encode token using ECDSA with P-256 and SHA-256
    # use this only for testing as private key is publicly available from ruby-jwt gem
    def encode_alb_token(payload)
      return nil if payload.blank? || !Rails.env.test?

      private_key =
        OpenSSL::PKey.read(
          File.read(
            Rails.root.join("spec", "fixtures", "certs", "ec256-private.pem").
              to_s,
          ),
        )
      JWT.encode(payload, private_key, "ES256")
    rescue OpenSSL::PKey::ECError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # encode token using RSA and SHA-512
    # use this only for testing as private key is publicly available from ruby-jwt gem
    def encode_globus_token(payload)
      return nil if payload.blank? || !Rails.env.test?

      private_key =
        OpenSSL::PKey.read(
          File.read(
            Rails.root.join("spec", "fixtures", "certs", "ec512-private.pem").
              to_s,
          ),
        )
      JWT.encode(payload, private_key, "RS512")
    rescue OpenSSL::PKey::ECError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # basic auth
    def encode_auth_param(username: nil, password: nil)
      return nil unless username.present? && password.present?

      ::Base64.strict_encode64("#{username}:#{password}")
    end

    # generate JWT token
    def generate_token(attributes = {})
      payload = {
        uid: attributes.fetch(:uid, "0000-0001-5489-3594"),
        name: attributes.fetch(:name, "Josiah Carberry"),
        email: attributes.fetch(:email, nil),
        provider_id: attributes.fetch(:provider_id, nil),
        client_id: attributes.fetch(:client_id, nil),
        role_id: attributes.fetch(:role_id, "staff_admin"),
        beta_tester: attributes.fetch(:beta_tester, nil),
        has_orcid_token: attributes.fetch(:has_orcid_token, nil),
        aud: attributes.fetch(:aud, Rails.env),
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30),
      }.compact

      encode_token(payload)
    end

    def generate_alb_token(attributes = {})
      preferred_username =
        attributes.fetch(:preferred_username, "0000-0001-5489-3594@orcid.org")

      payload = {
        uid: preferred_username[0..18],
        preferred_username: preferred_username,
        name: attributes.fetch(:name, "Josiah Carberry"),
        email: attributes.fetch(:email, nil),
        provider_id: attributes.fetch(:provider_id, nil),
        client_id: attributes.fetch(:client_id, nil),
        role_id: attributes.fetch(:role_id, "user"),
        aud: Rails.env,
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30),
      }.compact

      encode_alb_token(payload)
    end

    def get_payload(uid: nil, user: nil, password: nil)
      roles = {
        "ROLE_ADMIN" => "staff_admin",
        "ROLE_DATACENTRE" => "client_admin",
        "ROLE_ALLOCATOR" => "provider_admin",
        "ROLE_CONSORTIUM" => "provider_admin",
        "ROLE_CONTRACTUAL_PROVIDER" => "provider_admin",
        "ROLE_FOR_PROFIT_PROVIDER" => "provider_admin",
      }
      payload = {
        "uid" => uid,
        "role_id" => roles.fetch(user.role_name, "user"),
        "name" => user.name,
        "email" => user.contact_email,
      }

      # we only need password for clients registering DOIs in the handle system
      if uid.include? "."
        payload["provider_id"] = user.provider_id
        payload["client_id"] = uid
      elsif uid != "admin"
        payload["provider_id"] = uid
      end

      payload
    end
  end
end
