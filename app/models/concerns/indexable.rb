module Indexable
  extend ActiveSupport::Concern

  require 'aws-sdk-sqs'

  included do
    unless Rails.env.test?
      before_destroy { send_delete_message(self.to_jsonapi) }
      after_save { send_import_message(self.to_jsonapi) }
    end

    def send_delete_message(data)
      send_message(data, shoryuken_class: "ElasticDeleteWorker")
    end

    def send_import_message(data)
      send_message(data, shoryuken_class: "ElasticImportWorker")
    end
    
    # shoryuken_class is needed for the consumer to process the message
    # we use the AWS SQS client directly as there is no consumer in this app
    def send_message(body, options={})
      sqs = Aws::SQS::Client.new
      queue_url = sqs.get_queue_url(queue_name: "#{Rails.env}_elastic").queue_url
      options[:shoryuken_class] ||= "ElasticImportWorker"

      options = {
        queue_url: queue_url,
        message_attributes: {
          'shoryuken_class' => {
            string_value: options[:shoryuken_class],
            data_type: 'String'
          },
        },
        message_body: body.to_json,
      }

      sqs.send_message(options)
    end
  end
end
