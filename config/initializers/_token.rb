# frozen_string_literal: true

Rails.application.config.to_prepare do
  # generate token for jwt authentication with Profiles service, valid for 12 months
  ENV["VOLPINO_TOKEN"] = User.generate_token(exp: 3_600 * 30 * 12)
end
