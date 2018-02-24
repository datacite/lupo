module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    unless Rails.env.test?
      before_destroy { send_message(data: self.to_jsonapi, action: "destroy") }
      after_create { send_message(data: self.to_jsonapi, action: "create") }
      after_update { send_message(data: self.to_jsonapi, action: "update") }
    end

    # shoryuken_class is needed for the consumer to process the message
    # we use the AWS SQS client directly as there is no consumer in this app
    def send_message(body)
      sqs = Aws::SQS::Client.new
      queue_url = sqs.get_queue_url(queue_name: "#{Rails.env}_elastic").queue_url

      options = {
        queue_url: queue_url,
        message_attributes: {
          'shoryuken_class' => {
            string_value: "ElasticWorker",
            data_type: 'String'
          },
        },
        message_body: body.to_json,
      }

      sqs.send_message(options)
    end
  end
end
