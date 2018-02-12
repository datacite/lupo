class ElasticsearchJob < ActiveJob::Base
    queue_as :default

    rescue_from ActiveJob::DeserializationError, Faraday::TimeoutError do
        retry_job wait: 5.minutes, queue: :default
    end

    def perform(data, operation)
      options = { content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json', bearer: User.generate_token }
      controller = data.dig("data", "type")
      id = data.dig("data", "id")
      url = "#{ENV["LEVRIERO_URL"]}/#{controller}"
      Rails.logger.debug "Ingest into ElasticSearch #{url}"

      case operation
        when "index"
          result =  Maremma.post(url, content_type: options[:content_type], accept: options[:accept], bearer: options[:bearer], data: data.to_json)
          Rails.logger.info result.inspect
        when "delete"
          result =  Maremma.delete(url + "/" + id, content_type: options[:content_type], accept: options[:accept], bearer: options[:bearer])
          Rails.logger.info result.inspect
        else raise ArgumentError, "Unknown operation '#{operation}'"
      end
    end
end
