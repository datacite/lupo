class ElasticsearchJob < ActiveJob::Base
    queue_as :default

    rescue_from ActiveJob::DeserializationError, Faraday::TimeoutError do
        retry_job wait: 5.minutes, queue: :default
    end

    def perform(url, data)
        Rails.logger.debug "Ingest into ElasticSearch"
        result =  Maremma.post(url, content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json', bearer: ENV['JWT_TOKEN'], data: data.to_json)
        Rails.logger.info result.inspect
    end
end
  




