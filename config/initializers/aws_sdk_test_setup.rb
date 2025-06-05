# config/initializers/aws_sdk_test_setup.rb
if Rails.env.test? && defined?(Aws)
  aws_test_config = {
    region: ENV.fetch('AWS_REGION', 'us-stubbed-1'),
    credentials: Aws::Credentials.new('DUMMY_ACCESS_KEY_ID', 'DUMMY_SECRET_ACCESS_KEY'),
    stub_responses: true
  }
  Aws.config.update(aws_test_config) # Aws.config will be a Hash
end