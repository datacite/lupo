# load ENV variables from .env file if it exists
env_file = File.expand_path("../../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

# default values for some ENV variables
ENV['APPLICATION'] ||= "datacenter-api"
ENV['HOSTNAME'] ||= "fabbrica.local"
ENV['MEMCACHE_SERVERS'] ||= "memcached:11211"
ENV['SITE_TITLE'] ||= "Data Center API"
ENV['LOG_LEVEL'] ||= "info"
ENV['REDIS_URL'] ||= "redis://redis:6379/8"
ENV['ES_HOST'] ||= "elasticsearch:9200"
ENV['SOLR_HOST'] ||= "https://search.test.datacite.org/api"
ENV['CONCURRENCY'] ||= "25"
ENV['CDN_URL'] ||= "https://assets.datacite.org"
ENV['GITHUB_URL'] ||= "https://github.com/datacite/lupo"
ENV['SEARCH_URL'] ||= "https://search.datacite.org/"
ENV['TRUSTED_IP'] ||= "10.0.10.1"

# more detailed error reporting in development
if Rails.env.development?
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP']
end

Rails.application.config.log_level = ENV['LOG_LEVEL'].to_sym

# Use memcached as cache store
Rails.application.config.cache_store = :dalli_store, nil, { :namespace => ENV['APPLICATION'], :compress => true }
