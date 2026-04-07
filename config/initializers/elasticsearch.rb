# frozen_string_literal: true

require "faraday"
require "faraday_middleware/aws_sigv4"

# Bypass Elasticsearch product check to allow OpenSearch-compatible endpoints.
# elasticsearch-ruby 8.x raises UnsupportedProductError unless the server returns
# x-elastic-product: Elasticsearch, which OpenSearch does not.
module ElasticsearchV8OpenSearchBypass
  private
    def verify_elasticsearch(*args, &block)
      response = @transport.perform_request(*args, &block)
      @verified = true
      response
    end
end

Elasticsearch::Client.prepend(ElasticsearchV8OpenSearchBypass)

if ENV["ES_HOST"].end_with?(".datacite.org")
  Elasticsearch::Model.client =
    Elasticsearch::Client.new(
      host: ENV["ES_HOST"],
      port: "80",
      scheme: "http",
      request_timeout: ENV["ES_REQUEST_TIMEOUT"].to_i,
    ) do |f|
      f.request :aws_sigv4,
                credentials:
                  Aws::Credentials.new(
                    ENV["AWS_ACCESS_KEY_ID"],
                    ENV["AWS_SECRET_ACCESS_KEY"],
                  ),
                service: "es",
                region: ENV["AWS_REGION"]

      f.adapter :excon
    end
else
  Elasticsearch::Model.client =
    Elasticsearch::Client.new(
      host: ENV["ES_HOST"],
      port: ENV["ES_PORT"],
      scheme: ENV["ES_SCHEME"],
      user: "elastic",
      password: ENV["ELASTIC_PASSWORD"],
    ) { |f| f.adapter :excon }
end
