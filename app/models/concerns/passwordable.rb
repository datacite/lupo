module Passwordable
  extend ActiveSupport::Concern

  require 'digest'

  included do
    # "yes", "not set" (used in serializer) and a blank value are not allowed for new password
    def encrypt_password(password)
      return nil unless ENV["SESSION_ENCRYPTED_COOKIE_SALT"].present? && password.present? && !["yes", "not set"].include?(password)

      Digest::SHA256.hexdigest password + "{#{ENV["SESSION_ENCRYPTED_COOKIE_SALT"]}}"
    end
  end
end
