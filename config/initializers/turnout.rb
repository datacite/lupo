Turnout.configure do |config|
  config.default_maintenance_page = Turnout::MaintenancePage::JSON
  config.default_allowed_paths = ['^/heartbeat']
  config.default_reason = "The site is temporarily down for maintenance. Please check https://status.datacite.org for more information."
end