require 'flipper'
require 'flipper/adapters/http'
require "active_support/notifications"
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'

Flipper.configure do |config|
  config.default do
    configuration = {
      url: ENV['VOLPINO_URL'] + "/flipper",
      headers: { "Authorization" => "Bearer " + User.generate_token(exp: 3600 * 30) }
    }
    http_adapter = Flipper::Adapters::Http.new(configuration)
    cache = ActiveSupport::Cache::MemCacheStore.new(ENV['MEMCACHE_SERVERS'])
    adapter = Flipper::Adapters::ActiveSupportCacheStore.new(http_adapter, cache, expires_in: 1.hour)
    flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end
end

if Rails.env.development?
  require "flipper/instrumentation/log_subscriber"
  Flipper::Instrumentation::LogSubscriber.logger = ActiveSupport::Logger.new(STDOUT)
end

Flipper.register(:staff) do |actor|
  actor.respond_to?(:is_admin_or_staff?) && actor.is_admin_or_staff?
end

Flipper.register(:beta_testers) do |actor|
  actor.respond_to?(:is_beta_tester?) && actor.is_beta_tester?
end
