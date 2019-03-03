Audited.config do |config|
  config.current_user_method = :authenticated_user
  config.audit_class = Activity
end