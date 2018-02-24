module Indexable
  extend ActiveSupport::Concern

  included do
    unless Rails.env.test?
      before_destroy { send_message(data: self.to_jsonapi, action: "destroy") }
      after_create { send_message(data: self.to_jsonapi, action: "create") }
      after_update { send_message(data: self.to_jsonapi, action: "update") }
    end

    # shoryuken_class is needed for the consumer to process the message
    def send_message(body)
      options = {
        message_attributes: {
          'shoryuken_class' => {
            string_value: "ElasticWorker",
            data_type: 'String'
          },
        },
        message_body: body,
      }

      Shoryuken::Client.queues("#{Rails.env}_elastic").send_message(options)
    end
  end
end
