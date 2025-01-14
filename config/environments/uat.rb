# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Global enable/disable all memcached usage
  config.perform_caching = true

  # Disable/enable fragment and page caching in ActionController
  config.action_controller.perform_caching = true

  config.active_storage.service = :amazon

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  # config.active_record.dump_schema_after_migration = false

  config.paperclip_defaults = {
    storage: :s3,
    s3_protocol: "https",
    s3_host_alias: "assets.test.datacite.org",
    url: ":s3_alias_url",
    path: "/images/members/:filename",
    preserve_files: true,
    s3_host_name: "s3-eu-west-1.amazonaws.com",
    s3_credentials: {
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      s3_region: ENV["AWS_REGION"],
    },
    bucket: ENV["AWS_S3_BUCKET"],
  }
  Paperclip.options[:image_magick_path] = "/usr/bin/"
  Paperclip.options[:command_path] = "/usr/bin/"

  require "flipper/middleware/memoizer"
  config.middleware.use Flipper::Middleware::Memoizer
  config.flipper.memoize = false
end
