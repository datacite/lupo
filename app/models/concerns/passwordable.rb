module Passwordable
  extend ActiveSupport::Concern

  require 'digest'

  included do
    # set_password must be true to change a password
    # "yes", "not set" and a blank value are not allowed for new password
    def password=(value)
      return nil unless set_password == true && value.present? && !["yes", "not set"].include?(value)

      encrypted_password = encrypt_password(value)
      write_attribute(:password, encrypted_password)
    end

    def encrypt_password(password)
      return nil unless ENV["SESSION_ENCRYPTED_COOKIE_SALT"].present? && password.present?

      Digest::SHA256.hexdigest password + "{#{ENV["SESSION_ENCRYPTED_COOKIE_SALT"]}}"
    end
  end
end
