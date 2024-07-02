# frozen_string_literal: true

class User
  # include jwt encode and decode
  include Authenticable

  # include helper module for setting password
  include Passwordable

  # include helper module for sending emails via Mailgun API
  include Mailable

  # include helper module for caching infrequently changing resources
  include Cacheable

  attr_accessor :name,
                :uid,
                :email,
                :role_id,
                :jwt,
                :password,
                :provider_id,
                :client_id,
                :beta_tester,
                :has_orcid_token,
                :errors

  def initialize(credentials, options = {})
    if credentials.present? && options.fetch(:type, "").casecmp("basic").zero?
      username, password = ::Base64.decode64(credentials).split(":", 2)
      payload = decode_auth_param(username: username, password: password)
      @jwt =
        encode_token(
          payload.merge(
            iat: Time.now.to_i,
            exp: Time.now.to_i + 3_600 * 24 * 30,
            aud: Rails.env,
          ),
        )
    elsif credentials.present? && options.fetch(:type, "").casecmp("oidc").zero?
      payload = decode_alb_token(credentials)

      # globus auth preferred_username looks like 0000-0003-1419-2405@orcid.org
      # default to role user unless database says otherwise
      uid =
        if payload["preferred_username"].present?
          payload["preferred_username"][0..18]
        end

      if uid.present?
        payload = {
          "uid" => uid, "name" => payload["name"], "email" => payload["email"]
        }

        @jwt =
          encode_token(
            payload.merge(
              iat: Time.now.to_i,
              exp: Time.now.to_i + 3_600 * 24 * 30,
              aud: Rails.env,
            ),
          )
      end
    elsif credentials.present?
      payload = decode_token(credentials)
      @jwt = credentials
    end

    if payload.blank? || payload[:errors]
      @role_id = "anonymous"
      @errors = payload[:errors] if payload.present?
    else
      @uid = payload.fetch("uid", nil)
      @name = payload.fetch("name", nil)
      @email = payload.fetch("email", nil)
      @password = payload.fetch("password", nil)
      @role_id = payload.fetch("role_id", nil)
      @provider_id = payload.fetch("provider_id", nil)
      @client_id = payload.fetch("client_id", nil)
      @beta_tester = payload.fetch("beta_tester", false)
      @has_orcid_token = payload.fetch("has_orcid_token", false)
    end
  end

  alias_attribute :orcid, :uid
  alias_attribute :id, :uid
  alias_attribute :flipper_id, :uid
  alias_attribute :provider, :allocator
  alias_attribute :client, :datacentre

  # Helper method to check for admin user
  def is_admin?
    role_id == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    %w[staff_admin staff_user].include?(role_id)
  end

  # Helper method to check for beta tester
  def is_beta_tester?
    beta_tester
  end

  def provider
    return nil if provider_id.blank?

    Provider.where(symbol: provider_id).where(deleted_at: nil).first
  end

  def client
    return nil if client_id.blank?

    ::Client.where(symbol: client_id).where(deleted_at: nil).first
  end

  def self.reset(username)
    uid = username.downcase

    if uid.include?(".")
      user = Client.where(symbol: uid.upcase).where(deleted_at: nil).first
      client_id = uid
    elsif uid == "admin"
      user = Provider.where(symbol: uid.upcase).first
    else
      user = Provider.where(symbol: uid.upcase).where(deleted_at: nil).first
      provider_id = uid
    end

    return {} if user.blank?

    payload = {
      "uid" => uid,
      "role_id" => "temporary",
      "name" => user.name,
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
    title = ENV["BRACCO_TITLE"] 
    subject = "#{title}: Password Reset Request"
    account_type =
      if user.instance_of?(Provider)
        user.member_type.to_s.humanize
      else
        user.client_type.to_s.humanize
      end
    text =
      User.format_message_text(
        template: "users/reset_text",
        title: title,
        contact_name: user.name,
        name: user.symbol,
        url: url,
        reset_url: reset_url,
      )
    html =
      User.format_message_html(
        template: "users/reset",
        title: title,
        contact_name: user.name,
        name: user.symbol,
        url: url,
        reset_url: reset_url,
      )
    response =
      send_email_message(
        name: user.name,
        email: user.system_email,
        subject: subject,
        text: text,
        html: html,
      )

    fields = [
      { title: "Account ID", value: uid.upcase, short: true },
      { title: "Account type", value: account_type, short: true },
      { title: "Account name", value: user.name, short: true },
      { title: "System email", value: user.system_email, short: true },
    ]
    slack_title = subject + (response[:status] == 200 ? " Sent" : " Failed")
    level = response[:status] == 200 ? "good" : "danger"
    send_notification_to_slack(
      nil,
      title: slack_title, level: level, fields: fields,
    )

    response
  end
end
