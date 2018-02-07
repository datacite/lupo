module Mailable
  extend ActiveSupport::Concern

  require 'mailgun'
  require 'premailer'

  module ClassMethods
    def format_message_text(template: nil, contact_name: nil, name: nil, url: nil)
      ActionController::Base.render(
        assigns: { contact_name: contact_name, name: name, url: url },
        template: template,
        layout: false
      )
    end

    def format_message_html(template: nil, contact_name: nil, name: nil, url: nil)
      input = ActionController::Base.render(
        assigns: { contact_name: contact_name, name: name, url: url },
        template: template,
        layout: "application"
      )

      premailer = Premailer.new(input, with_html_string: true, warn_level: Premailer::Warnings::SAFE)
      premailer.to_inline_css
    end

    def send_message(name: nil, email: nil, subject: nil, text: nil, html: nil)
      mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
      mb_obj = Mailgun::MessageBuilder.new

      mb_obj.from(ENV['MG_FROM'], "last" => "DataCite Support")
      mb_obj.add_recipient(:to, email, "last" => name)
      mb_obj.subject(subject)
      mb_obj.body_text(text)
      mb_obj.body_html(html)

      response = mg_client.send_message(ENV['MG_DOMAIN'], mb_obj)
      body = JSON.parse(response.body)

      { id: body["id"], message: body["message"], status: response.code }
    end
  end
end
