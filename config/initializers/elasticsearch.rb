# frozen_string_literal: true

require "faraday"
require "faraday_middleware/aws_sigv4"

if ENV["ES_HOST"] == "elasticsearch.test.datacite.org" ||
    ENV["ES_HOST"] == "elasticsearch.datacite.org"
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

# Monkeypactch to ignore the Elasticsearch::UnsupportedProductError.
# This error is raised because our gem version does not match the elasticsearch version in AWS OpenSearch.
# As such, it should be safe to ignore the error.
module Elasticsearch
  class Client
    alias original_verify_with_version_or_header verify_with_version_or_header

    def verify_with_version_or_header(...)
      original_verify_with_version_or_header(...)
    rescue Elasticsearch::UnsupportedProductError => exception
      warn("Ignoring elasticsearch complaint: #{exception.message}")
    end
  end
end
