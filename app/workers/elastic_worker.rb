class ElasticWorker
  include Shoryuken::Worker

  shoryuken_options queue: ->{ "#{ENV['RAILS_ENV']}_elastic" }

  def self.perform_async(body, options = {})
    options ||= {}
    options[:message_attributes] ||= {}
    options[:message_attributes]['shoryuken_class'] = {
      string_value: self.to_s,
      data_type: 'String'
    }

    options[:message_body] = body

    queue_name = options.delete(:queue) || get_shoryuken_options['queue']

    Shoryuken::Client.queues(queue_name).send_message(options)
  end
end
