module Mailable
  extend ActiveSupport::Concern

  require 'mailgun'
  require 'premailer'
  require 'slack-notifier'

  included do
    def send_welcome_email(responsible_id: nil)
      if self.class.name == "Provider"
        client_id = nil
        provider_id = symbol.downcase
      elsif self.class.name == "Client"
        client_id = symbol.downcase
        provider_id = provider_id
      end

      payload = {
        "uid" => symbol.downcase,
        "role_id" => "temporary",
        "name" => name,
        "client_id" => client_id,
        "provider_id" => provider_id
      }.compact

      jwt = encode_token(payload.merge(iat: Time.now.to_i, exp: Time.now.to_i + 3600 * 24, aud: Rails.env))
      url = ENV['BRACCO_URL'] + "?jwt=" + jwt
      reset_url = ENV['BRACCO_URL'] + "/reset"
      title = Rails.env.stage? ? "DataCite Fabrica Test" : "DataCite Fabrica"
      subject = "#{title}: New Account"
      account_type = self.class.name == "Provider" ? member_type.humanize : client_type.humanize
      responsible_id ||= "ADMIN"
      text = User.format_message_text(template: "users/welcome.text.erb", title: title, contact_name: name, name: symbol, url: url, reset_url: reset_url)
      html = User.format_message_html(template: "users/welcome.html.erb", title: title, contact_name: name, name: symbol, url: url, reset_url: reset_url)

      response = User.send_message(name: name, email: system_email, subject: subject, text: text, html: html)

      fields = [
        { title: "Account ID", value: symbol, short: true },
        { title: "Account type", value: account_type, short: true },
        { title: "Account name", value: name, short: true },
        { title: "System email", value: system_email, short: true },
        { title: "Responsible Account ID", value: responsible_id }
      ]
      User.send_notification_to_slack(nil, title: subject, level: "good", fields: fields)

      response
    end

    def send_delete_email(responsible_id: nil)
      title = Rails.env.stage? ? "DataCite Fabrica Test" : "DataCite Fabrica"
      subject = "#{title}: Account Deleted"
      account_type = self.class.name == "Provider" ? member_type.humanize : client_type.humanize
      responsible_id ||= "ADMIN"
      text = User.format_message_text(template: "users/delete.text.erb", title: title, contact_name: name, name: symbol)
      html = User.format_message_html(template: "users/delete.html.erb", title: title, contact_name: name, name: symbol)

      response = User.send_message(name: name, email: system_email, subject: subject, text: text, html: html)

      fields = [
        { title: "Account ID", value: symbol, short: true },
        { title: "Account type", value: account_type, short: true },
        { title: "Account name", value: name, short: true },
        { title: "System email", value: system_email, short: true },
        { title: "Responsible Account ID", value: responsible_id }
      ]
      User.send_notification_to_slack(nil, title: subject, level: "warning", fields: fields)

      response
    end
  end

  module ClassMethods
    # icon for Slack messages
    SLACK_ICON_URL = "https://github.com/datacite/segugio/blob/master/source/images/fabrica.png"

    def format_message_text(template: nil, title: nil, contact_name: nil, name: nil, url: nil, reset_url: nil)
      ActionController::Base.render(
        assigns: { title: title, contact_name: name, name: name, url: url, reset_url: reset_url },
        template: template,
        layout: false
      )
    end

    def format_message_html(template: nil, title: nil, contact_name: nil, name: nil, url: nil, reset_url: nil)
      input = ActionController::Base.render(
        assigns: { title: title, contact_name: name, name: name, url: url, reset_url: reset_url },
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

    def send_notification_to_slack(text, options={})
      return nil unless ENV['SLACK_WEBHOOK_URL'].present?

      attachment = {
        title: options[:title] || "Fabrica Message",
        text: text,
        color: options[:level] || "good",
        fields: options[:fields]
      }.compact

      notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'],
                                     username: "Fabrica",
                                     icon_url: SLACK_ICON_URL
      response = notifier.ping attachments: [attachment]
      response.first.body
    rescue Slack::Notifier::APIError => exception
      Rails.logger.error exception.message unless exception.message.include?("HTTP Code 429")
    end
  end
end
