# frozen_string_literal: true

module Mailable
  extend ActiveSupport::Concern

  require "mailgun"
  require "premailer"
  require "slack-notifier"

  included do
    def send_welcome_email(responsible_id: nil)
      if instance_of?(Provider)
        client_id = nil
        provider_id = symbol.downcase
      elsif instance_of?(Client)
        client_id = symbol.downcase
        provider_id = provider_id
      end

      payload = {
        "uid" => symbol.downcase,
        "role_id" => "temporary",
        "name" => name,
        "client_id" => client_id,
        "provider_id" => provider_id,
      }.compact

      jwt =
        encode_token(
          payload.merge(
            iat: Time.now.to_i, exp: Time.now.to_i + 3_600 * 24, aud: Rails.env,
          ),
        )
      url = ENV["BRACCO_URL"] + "?jwt=" + jwt
      reset_url = ENV["BRACCO_URL"] + "/reset"
      title = if Rails.env.stage?
        if ENV["ES_PREFIX"].present?
          "DataCite Fabrica Stage"
        else
          "DataCite Fabrica Test"
        end
      else
        "DataCite Fabrica"
      end
      subject = "#{title}: New Account"
      account_type =
        if instance_of?(Provider)
          member_type.humanize
        else
          client_type.humanize
        end
      responsible_id = (responsible_id || "admin").upcase
      text =
        User.format_message_text(
          template: "users/welcome_text",
          title: title,
          contact_name: name,
          name: symbol,
          url: url,
          reset_url: reset_url,
        )
      html =
        User.format_message_html(
          template: "users/welcome",
          title: title,
          contact_name: name,
          name: symbol,
          url: url,
          reset_url: reset_url,
        )

      response =
        User.send_email_message(
          name: name,
          email: system_email,
          subject: subject,
          text: text,
          html: html,
        )

      fields = [
        { title: "Account ID", value: symbol, short: true },
        { title: "Account type", value: account_type, short: true },
        { title: "Account name", value: name, short: true },
        { title: "System email", value: system_email, short: true },
        { title: "Responsible Account ID", value: responsible_id },
      ]
      User.send_notification_to_slack(
        nil,
        title: subject, level: "good", fields: fields,
      )

      response
    end

    def send_delete_email(responsible_id: nil)
      title = Rails.env.stage? ? "DataCite Fabrica Test" : "DataCite Fabrica"
      subject = "#{title}: Account Deleted"
      account_type =
        if instance_of?(Provider)
          member_type.humanize
        else
          client_type.humanize
        end
      responsible_id ||= "ADMIN"
      text =
        User.format_message_text(
          template: "users/delete_text",
          title: title,
          contact_name: name,
          name: symbol,
        )
      html =
        User.format_message_html(
          template: "users/delete",
          title: title,
          contact_name: name,
          name: symbol,
        )

      response =
        User.send_email_message(
          name: name,
          email: system_email,
          subject: subject,
          text: text,
          html: html,
        )

      fields = [
        { title: "Account ID", value: symbol, short: true },
        { title: "Account type", value: account_type, short: true },
        { title: "Account name", value: name, short: true },
        { title: "System email", value: system_email, short: true },
        { title: "Responsible Account ID", value: responsible_id },
      ]
      User.send_notification_to_slack(
        nil,
        title: subject, level: "warning", fields: fields,
      )

      response
    end
  end

  module ClassMethods
    # icon for Slack messages
    SLACK_ICON_URL =
      "https://github.com/datacite/segugio/blob/master/source/images/fabrica.png"

    class NoOpHTTPClient
      def self.post(_uri, params = {})
        Rails.logger.info JSON.parse(params[:payload])
        OpenStruct.new(body: "ok", status: 200)
      end
    end

    def format_message_text(
      template: nil,
      title: nil,
      contact_name: nil,
      name: nil,
      url: nil,
      reset_url: nil
    )
      ActionController::Base.render(
        assigns: {
          title: title,
          contact_name: contact_name,
          name: name,
          url: url,
          reset_url: reset_url,
        },
        template: template,
        format: [:text],
        layout: false,
      )
    end

    def format_message_html(
      template: nil,
      title: nil,
      contact_name: nil,
      name: nil,
      url: nil,
      reset_url: nil
    )
      input =
        ActionController::Base.render(
          assigns: {
            title: title,
            contact_name: contact_name,
            name: name,
            url: url,
            reset_url: reset_url,
          },
          template: template,
          format: [:html],
          layout: "application",
        )

      premailer =
        Premailer.new(
          input,
          with_html_string: true, warn_level: Premailer::Warnings::SAFE,
        )
      premailer.to_inline_css
    end

    def send_email_message(
      name: nil, email: nil, subject: nil, text: nil, html: nil
    )
      mg_client = Mailgun::Client.new ENV["MAILGUN_API_KEY"]
      mg_client.enable_test_mode! if Rails.env.test?
      mb_obj = Mailgun::MessageBuilder.new

      mb_obj.from(ENV["MG_FROM"], "last" => "DataCite Support")
      mb_obj.add_recipient(:to, email, "last" => name)
      mb_obj.subject(subject)
      mb_obj.body_text(text)
      mb_obj.body_html(html)

      response = mg_client.send_message(ENV["MG_DOMAIN"], mb_obj)
      body = JSON.parse(response.body)

      { id: body["id"], message: body["message"], status: response.code }
    end

    def send_notification_to_slack(text, options = {})
      return nil if ENV["SLACK_WEBHOOK_URL"].blank?

      attachment = {
        title: options[:title] || "Fabrica Message",
        text: text,
        color: options[:level] || "good",
        fields: options[:fields],
      }.compact

      # don't send message to Slack API in test and development environments
      notifier =
        if Rails.env.test? || Rails.env.development?
          Slack::Notifier.new ENV["SLACK_WEBHOOK_URL"],
                              username: "Fabrica", icon_url: SLACK_ICON_URL do
            http_client NoOpHTTPClient
          end
        else
          Slack::Notifier.new ENV["SLACK_WEBHOOK_URL"],
                              username: "Fabrica", icon_url: SLACK_ICON_URL
        end

      response = notifier.ping attachments: [attachment]
      response.first.body
    rescue Slack::Notifier::APIError => e
      Rails.logger.error e.message unless e.message.include?("HTTP Code 429")
    end
  end
end
