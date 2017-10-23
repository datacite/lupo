require 'faraday_middleware/aws_signers_v4'

config = {
  host: ENV['ES_HOST'],
  transport_options: {
    request: { timeout: 5 }
  }
}

if File.exists?("config/elasticsearch.yml")
  # config.merge!(YAML.load_file("config/elasticsearch.yml")[Rails.env].symbolize_keys)
  config.merge!(YAML.load_file("config/elasticsearch.yml").symbolize_keys)
end

Elasticsearch::Model.client = Elasticsearch::Client.new(config)

# Elasticsearch::Model.client = Elasticsearch::Client.new(host: ENV['ES_HOST'], port: '443') do |f|
#   f.request :aws_signers_v4,
#     credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_ACCESS_KEY']),
#     service_name: ENV['ES_NAME'],
#     region: ENV['AWS_REGION']
#
#   f.response :logger
#   f.adapter  Faraday.default_adapter
# end
