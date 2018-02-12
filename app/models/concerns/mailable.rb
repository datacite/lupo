module Mailable
  extend ActiveSupport::Concern

  require 'mailgun'
  require 'premailer'

  included do
    def send_welcome_email
      if self.class.name == "Provider"
        client_id = nil
        provider_id = symbol.downcase
      elsif self.class.name == "Client"
        client_id = symbol.downcase
        provider_id = provider_id
      end

      payload = {
        "uid" => symbol.downcase,
        "role_id" => "user",
        "name" => name,
        "client_id" => client_id,
        "provider_id" => provider_id
      }.compact

      jwt = encode_token(payload.merge(iat: Time.now.to_i, exp: Time.now.to_i + 3600 * 24))
      url = ENV['DOI_URL'] + "?jwt=" + jwt

      title = Rails.env.stage? ? "DataCite DOI Fabrica Test" : "DataCite DOI Fabrica"
      subject = "#{title}: New Account"
      text = User.format_message_text(template: "users/welcome.text.erb", title: title, contact_name: contact_name, name: symbol, url: url)
      html = User.format_message_html(template: "users/welcome.html.erb", title: title, contact_name: contact_name, name: symbol, url: url)

      User.send_message(name: contact_name, email: contact_email, subject: subject, text: text, html: html)
    end
  end

  module ClassMethods
    def format_message_text(template: nil, title: nil, contact_name: nil, name: nil, url: nil)
      ActionController::Base.render(
        assigns: { title: title, contact_name: contact_name, name: name, url: url },
        template: template,
        layout: false
      )
    end

    def format_message_html(template: nil, title: nil, contact_name: nil, name: nil, url: nil)
      input = ActionController::Base.render(
        assigns: { title: title, contact_name: contact_name, name: name, url: url },
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
