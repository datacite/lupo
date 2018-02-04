module Mailable
  extend ActiveSupport::Concern

  require 'mailgun'

  module ClassMethods
    def send_message(name: nil, email: nil, subject: nil, text: nil)
      mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
      mb_obj = Mailgun::MessageBuilder.new

      mb_obj.from(ENV['MG_FROM'], "last" => "DataCite Support")
      mb_obj.add_recipient(:to, email, "last" => name)
      mb_obj.subject(subject)
      mb_obj.body_text(text)

      response = mg_client.send_message(ENV['MG_DOMAIN'], mb_obj)
      body = JSON.parse(response.body)
      
      { id: body["id"], message: body["message"], status: response.code }
    end
  end
end
