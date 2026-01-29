# frozen_string_literal: true

source "https://rubygems.org"

gem "aasm", "~> 5.0", ">= 5.0.1"
gem "active_model_serializers", "~> 0.10.0"
gem "activerecord_json_validator", "~> 2.1", ">= 2.1.5"
gem "apollo-federation", "~> 3.8"
gem "audited", "~> 5.8"
gem "aws-sdk-core", "~> 3.226"
gem "aws-sdk-s3"
gem "aws-sdk-sqs", "~> 1.3"
gem "base32-url", "~> 0.3"
gem "batch-loader", "~> 1.4", ">= 1.4.1"
gem "bcrypt", "~> 3.1.7"
gem "bolognese", "~> 2.5.0"
gem "bootsnap", "~> 1.4", ">= 1.4.4", require: false
gem "cancancan", "~> 3.0"
gem "countries", "~> 2.1", ">= 2.1.2"
gem "crawler_detect"
gem "dalli", "~> 3.2", ">= 3.2.8"
gem "departure", "~> 6.2"
gem "diffy", "~> 3.2", ">= 3.2.1"
gem "dotenv"
gem "elasticsearch", "~> 7.17", ">= 7.17.10"
gem "elasticsearch-model", "~> 7.2.1", ">= 7.2.1", require: "elasticsearch/model"
gem "elasticsearch-rails", "~> 7.2.1", ">= 7.2.1"
gem "elasticsearch-transport", "~> 7.17", ">= 7.17.10"
gem "equivalent-xml", "~> 0.6.0"
gem "facets", require: false
gem "faraday", "~> 2.9"
gem "faraday_middleware-aws-sigv4", "~> 0.3.0"
# IMPORTANT!!!
# We have monkey patched this gem -> config/initializers/serialization_core.rb
# Please check this before upgrading/downgrading versions
gem "jsonapi-serializer", "~> 2.2"
gem "flipper", "~> 1.2", ">= 1.2.2"
gem "flipper-active_support_cache_store"
gem "gender_detector", "~> 0.1.2"
gem "git", "~> 1.11"
gem "google-protobuf", ">= 3.25.5"
gem "graphql", "2.0.0"
gem "graphql-batch", "~> 0.5.1"
gem "hashid-rails", "~> 1.4"
gem "iso-639", "~> 0.3.5"
gem "iso8601", "~> 0.9.0"
gem "jsonlint", "~> 0.3.0"
gem "jwt"
gem "kaminari", "~> 1.2"
gem "kt-paperclip", "~> 7.2", ">= 7.2.2"
gem "lograge", "~> 0.11.2"
gem "logstash-event", "~> 1.2", ">= 1.2.02"
gem "logstash-logger", "~> 0.26.1"
gem "mailgun-ruby", "~> 1.1", ">= 1.1.8"
gem "maremma", "~> 5.0"
gem "mini_magick", "~> 4.8"
gem "mysql2", "~> 0.5.3"
gem "nokogiri", ">= 1.11.2"
gem "oj", ">= 2.8.3"
gem "oj_mimic_json", "~> 1.0", ">= 1.0.1"
gem "premailer", "~> 1.11", ">= 1.11.1"
gem "pwqgen.rb", "~> 0.1.0"
gem "rack-cors", "~> 1.0", require: "rack/cors"
gem "rack-utf8_sanitizer", "~> 1.6"
gem "rails", "~> 7.2"
gem "rake", "~> 12.0"
gem "sentry-ruby", "~> 5.20"
gem "sentry-rails", "~> 5.20"
gem "shoryuken", "~> 7.0"
gem "simple_command"
gem "slack-notifier", "~> 2.1"
gem "sparql", "~> 3.1", ">= 3.1.2"
gem "sprockets", "~> 3.7", ">= 3.7.2"
gem "string_pattern"
gem "strip_attributes", "~> 1.8"
gem "turnout", "~> 2.5"
gem "uuid", "~> 2.3", ">= 2.3.9"
gem "parallel", "~> 1.27"

group :production, :stage do
  gem "datadog", require: "datadog/auto_instrument"
end

group :development, :test do
  gem "better_errors"
  gem "binding_of_caller"
  gem "bullet", "~> 8.1"
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-benchmark", "~> 0.4.0"
  gem "rspec-graphql_matchers", "2.0.0.pre.rc.0"
  gem "rspec-rails", "~> 6.1", ">= 6.1.1"
end

group :development do
  gem "brakeman", "~> 6.1", ">= 6.1.2"
  gem "bundler-audit", "~> 0.9.1"
  gem "fasterer", "~> 0.11.0"
  gem "listen", "~> 3.9"
  gem "reek", "~> 6.3"
  gem "seedbank"
  gem "spring", "~> 4.1", ">= 4.1.3"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.1"
  gem "rubocop", "~> 1.79.2", require: false
  gem "rubocop-performance", "~> 1.5", ">= 1.5.1", require: false
  gem "rubocop-rails", "~> 2.8", ">= 2.8.1", require: false
  gem "rubocop-packaging", "~> 0.5.1", require: false
  gem "rubocop-rspec", "~> 2.0", require: false
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record", "~> 2.2", ">= 2.2.2"
  gem "elasticsearch-extensions", "~> 0.0.29"
  gem "factory_bot_rails", "~> 6.4", ">= 6.4.3"
  gem "faker", "~> 3.2", ">= 3.2.3"
  gem "hashdiff", [">= 1.0.0.beta1", "< 2.0.0"]
  gem "shoulda-matchers", "~> 4.1", ">= 4.1.2"
  gem "simplecov", "~> 0.22.0"
  gem "test-prof", "~> 0.10.2"
  gem "vcr", "~> 6.1"
  gem "webmock", "~> 3.18", ">= 3.18.1"
  gem "parallel_tests", "~> 3.12"
  gem "rspec-sqlimit"
end
