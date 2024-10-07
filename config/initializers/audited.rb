# frozen_string_literal: true

Rails.application.config.to_prepare do
  Audited.config do |config|
    config.current_user_method = :authenticated_user
    config.audit_class = Activity
  end
end
