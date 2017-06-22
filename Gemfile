source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'
#
gem 'faker'

# gem 'rack-cors'
gem 'dotenv'
gem 'multi_json'
gem 'json', '~> 1.8', '>= 1.8.5'
gem 'oj', '~> 2.18', '>= 2.18.1'
gem 'equivalent-xml', '~> 0.6.0'
gem 'nokogiri', '~> 1.6', '>= 1.6.8'
gem 'iso8601', '~> 0.9.0'
gem 'maremma', '~> 3.5'
gem 'bolognese', '~> 0.9'
gem "dalli", "~> 2.7.6"
gem 'lograge', '~> 0.5'
gem 'bugsnag', '~> 5.3'
gem 'librato-rails', '~> 1.4.2'
gem 'gender_detector', '~> 0.1.2'
gem 'active_model_serializers', '~> 0.10.0'
gem 'jwt'
# gem 'jsonapi-resources'
# gem 'jsonapi-utils', '~> 0.4.9'
gem 'mysql2'

group :development, :test do
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem "better_errors"
  gem "binding_of_caller"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem 'capybara'
  gem 'webmock', '~> 1.20.0'
  gem 'vcr', '~> 3.0.3'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'simplecov'

  gem 'factory_girl_rails', '~> 4.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'faker'
  gem 'database_cleaner'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
