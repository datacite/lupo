module Passwordable
  extend ActiveSupport::Concern

  require 'digest'

  included do
    # "yes", "not set" (used in serializer) and a blank value are not allowed for new password
    def encrypt_password_sha256(password)
      return nil unless ENV["SESSION_ENCRYPTED_COOKIE_SALT"].present? && password.present?

      Digest::SHA256.hexdigest password.to_s + "{" + ENV["SESSION_ENCRYPTED_COOKIE_SALT"] + "}"
    end

    def authenticate_sha256(unencrypted_password)
      password == encrypt_password_sha256(unencrypted_password) && self
    end
  end
end
