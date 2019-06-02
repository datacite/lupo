# frozen_string_literal: true

require 'faraday_middleware'
require 'faraday_middleware/aws_sigv4'

if ENV['ES_HOST'] == "elasticsearch:9200"
  config = {
    host: ENV['ES_HOST'],
    transport_options: {
      request: { timeout: 30 }
    }
  }
  Elasticsearch::Model.client = Elasticsearch::Client.new(host: ENV['ES_HOST'], user: "elastic", password: ENV['ELASTIC_PASSWORD']) do |f|
    f.adapter :excon
  end
else
  Elasticsearch::Model.client = Elasticsearch::Client.new(host: ENV['ES_HOST'], port: '80', scheme: 'http') do |f|
    f.request :aws_sigv4,
      credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
      service: 'es',
      region: ENV['AWS_REGION']

    f.adapter :excon
  end
end
