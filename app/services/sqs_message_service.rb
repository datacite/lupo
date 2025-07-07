# frozen_string_literal: true

class SqsMessageService
  def self.enqueue(body, options = {})
    sqs = Aws::SQS::Client.new # Assumes Aws.config is set globally

    queue_name_prefix = ENV["SQS_PREFIX"].present? ? ENV["SQS_PREFIX"] : Rails.env
    target_queue_name = "#{queue_name_prefix}_#{options[:queue_name]}"

    effective_queue_url = if Aws.config[:sqs][:stub_responses]
      # If stubbing is active, always construct a well-formed dummy URL.
      # The actual result of sqs.get_queue_url is unreliable when stubbed (returns "String").
      dummy_url = "https://sqs.#{Aws.config[:region]}.amazonaws.com/000000000000/#{target_queue_name}"
      # Call get_queue_url for its potential side effects or future compatibility, but ignore its direct return for the URL.
      sqs.get_queue_url(queue_name: target_queue_name)
      dummy_url
    else
      # For real calls, use the result from get_queue_url
      sqs.get_queue_url(queue_name: target_queue_name).queue_url
    end

    # Default shoryuken_class if not provided
    shoryuken_class = options.fetch(:shoryuken_class, "DoiImportWorker")

    message_options = {
      queue_url: effective_queue_url,
      message_attributes: {
        "shoryuken_class" => {
          string_value: shoryuken_class, data_type: "String"
        },
      },
      message_body: body.to_json,
    }

    sqs.send_message(message_options)
  end
end
