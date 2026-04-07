# frozen_string_literal: true

source "https://rubygems.org"

gem "aasm", "~> 5.5", ">= 5.5.2"
gem "active_model_serializers", "~> 0.10.16"
gem "activerecord_json_validator", "~> 3.1"
gem "apollo-federation", "~> 3.10", ">= 3.10.3"
gem "audited", "~> 5.8"
gem "aws-sdk-core", "~> 3.244"
gem "aws-sdk-s3", "~> 1.218"
gem "aws-sdk-sqs", "~> 1.112"
gem "base32-url", "~> 0.7.0"
gem "batch-loader", "~> 2.0", ">= 2.0.6"
gem "bolognese", "~> 2.6"
gem "bootsnap", "~> 1.23"
gem "cancancan", "~> 3.6", ">= 3.6.1"
gem "countries", "~> 8.1"
gem "crawler_detect", "~> 1.2", ">= 1.2.11"
gem "dalli", "~> 5.0", ">= 5.0.2"
gem "departure", "~> 8.0"
gem "dotenv", "~> 3.2"
gem "elasticsearch", "~> 8.19", ">= 8.19.3"
gem "elasticsearch-model", "~> 8.0", ">= 8.0.1", require: "elasticsearch/model"
gem "elasticsearch-rails", "~> 8.0", ">= 8.0.1"
gem "elastic-transport", "~> 8.0", ">= 8.0.1"
gem "facets", "~> 3.2", require: false
gem "faraday", "~> 2.14", ">= 2.14.1"
gem "faraday_middleware-aws-sigv4", "~> 1.0", ">= 1.0.1"
# IMPORTANT!!!
# We have monkey patched this gem -> config/initializers/serialization_core.rb
# Please check this before upgrading/downgrading versions
gem "jsonapi-serializer", "~> 2.2"
gem "flipper", "~> 1.4", ">= 1.4.1"
gem "flipper-active_support_cache_store", "~> 1.4", ">= 1.4.1"
gem "gender_detector", "~> 2.1"
gem "google-protobuf", "~> 4.34", ">= 4.34.1"
gem "graphql", "~> 2.5", ">= 2.5.22"
gem "graphql-batch", "~> 0.6.1"
gem "hashid-rails", "~> 1.4", ">= 1.4.1"
gem "iso-639", "~> 0.3.8"
gem "iso8601", "~> 0.13.0"
gem "jsonlint", "~> 0.4.0"
gem "jwt", "~> 3.1", ">= 3.1.2"
gem "kaminari", "~> 1.2", ">= 1.2.2"
gem "kt-paperclip", "~> 7.3"
gem "lograge", "~> 0.14.0"
gem "logstash-logger", "~> 1.0"
gem "mailgun-ruby", "~> 1.4", ">= 1.4.3"
gem "maremma", "~> 6.0"
gem "mini_magick", "~> 5.3", ">= 5.3.1"
gem "mysql2", "~> 0.5.7"
gem "nokogiri", ">= 1.19", ">= 1.19.2"
gem "premailer", "~> 1.29"
gem "pwqgen.rb", "~> 0.1.0"
gem "rack-cors", "~> 3.0", require: "rack/cors"
gem "rack-utf8_sanitizer", "~> 1.11", ">= 1.11.1"
gem "rails", "~> 8.1", ">= 8.1.3"
gem "rake", "~> 13.3", ">= 13.3.1"
gem "sentry-ruby", "~> 6.5"
gem "sentry-rails", "~> 6.5"
gem "shoryuken", "~> 7.0", ">= 7.0.1"
gem "slack-notifier", "~> 2.1"
gem "sparql", "~> 3.1", ">= 3.1.2"
gem "strip_attributes", "~> 2.0", ">= 2.0.1"
gem "parallel", "~> 1.28"

group :production, :stage do
  gem "datadog", "~> 2.30", require: "datadog/auto_instrument"
end

group :development, :test do
  gem "bullet", "~> 8.1"
  gem "byebug", "~> 13.0", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 8.0", ">= 8.0.4"
end

group :development do
  gem "brakeman", "~> 8.0", ">= 8.0.4"
  gem "bundler-audit", "~> 0.9.3"
  gem "fasterer", "~> 0.11.0" # possible removal
  gem "listen", "~> 3.10"
  gem "reek", "~> 6.5" # possible removal
  gem "seedbank", "~> 0.5.0" # possible removal
  gem "rubocop", "~> 1.86", require: false
  gem "rubocop-performance", "~> 1.26", ">= 1.26.1", require: false
  gem "rubocop-rails", "~> 2.34", ">= 2.34.3", require: false
  gem "rubocop-packaging", "~> 0.6.0", require: false
  gem "rubocop-rspec", "~> 3.9", require: false
end

group :test do
  gem "database_cleaner-active_record", "~> 2.2", ">= 2.2.2"
  gem "factory_bot_rails", "~> 6.5", ">= 6.5.1"
  gem "faker", "~> 3.6", ">= 3.6.1"
  gem "hashdiff", "~> 1.2", ">= 1.2.1"
  gem "shoulda-matchers", "~> 7.0", ">= 7.0.1"
  gem "simplecov", "~> 0.22.0"
  gem "test-prof", "~> 1.6", ">= 1.6.1"
  gem "vcr", "~> 6.4"
  gem "webmock", "~> 3.26", ">= 3.26.2"
  gem "parallel_tests", "~> 5.6"
  gem "rspec-sqlimit", "~> 1.0"
end
