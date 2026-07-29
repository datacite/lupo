# frozen_string_literal: true

module Passwordable
  extend ActiveSupport::Concern

  require "digest"

  class_methods do
    # timing-safe compare to prevent timing attacks
    def secure_compare(a, b)
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize
      l = a.unpack "C#{a.bytesize}"
      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end

  included do
    # "yes", "not set" (used in serializer) and a blank value are not allowed for new password
    def encrypt_password_sha256(password)
      unless ENV["SESSION_ENCRYPTED_COOKIE_SALT"].present? && password.present?
        return nil
      end

      Digest::SHA256.hexdigest password.to_s + "{" +
        ENV["SESSION_ENCRYPTED_COOKIE_SALT"] +
        "}"
    end

    def authenticate_sha256(unencrypted_password)
      password == encrypt_password_sha256(unencrypted_password) && self
    end

    # delegate to class for convenience
    def secure_compare(a, b)
      self.class.secure_compare(a, b)
    end
  end
end
