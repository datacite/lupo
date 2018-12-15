class User
  # include jwt encode and decode
  include Authenticable

  # include helper module for setting password
  include Passwordable

  # include helper module for setting emails via Mailgun API
  include Mailable

  # include helper module for caching infrequently changing resources
  include Cacheable

  attr_accessor :name, :uid, :email, :role_id, :jwt, :password, :provider_id, :client_id, :beta_tester, :errors

  def initialize(credentials, options={})
    if credentials.present? && options.fetch(:type, "").downcase == "basic"
      username, password = ::Base64.decode64(credentials).split(":", 2)
      payload = decode_auth_param(username: username, password: password)
      @jwt = encode_token(payload.merge(iat: Time.now.to_i, exp: Time.now.to_i + 3600 * 24 * 30))
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
    ["staff_admin", "staff_user"].include?(role_id)
  end

  # Helper method to check for beta tester
  def is_beta_tester?
    beta_tester
  end

  def provider
    return nil unless provider_id.present?

    cached_provider_response(provider_id)
  end

  def client
    return nil unless client_id.present?

    cached_client_response(client_id)
  end

  def self.reset(username)
    uid = username.downcase

    if uid.include?(".")
      user = Client.where(symbol: uid.upcase).first
      client_id = uid
    elsif uid == "admin"
      user = Provider.unscoped.where(symbol: uid.upcase).first
    else
      user = Provider.where(symbol: uid.upcase).first
      provider_id = uid
    end

    return {} unless user.present?

    payload = {
      "uid" => uid,
      "role_id" => "user",
      "name" => user.name,
      "client_id" => client_id,
      "provider_id" => provider_id
    }.compact

    jwt = encode_token(payload.merge(iat: Time.now.to_i, exp: Time.now.to_i + 3600 * 24))
    url = ENV['BRACCO_URL'] + "?jwt=" + jwt
    reset_url = ENV['BRACCO_URL'] + "/reset"
    title = Rails.env.stage? ? "DataCite DOI Fabrica Test" : "DataCite DOI Fabrica"
    subject = "#{title}: Password Reset Request"
    text = User.format_message_text(template: "users/reset.text.erb", title: title, contact_name: user.contact_name, name: user.symbol, url: url, reset_url: reset_url)
    html = User.format_message_html(template: "users/reset.html.erb", title: title, contact_name: user.contact_name, name: user.symbol, url: url, reset_url: reset_url)
    response = self.send_message(name: user.contact_name, email: user.contact_email, subject: subject, text: text, html: html)

    fields = [
      { title: "Account ID", value: uid.upcase},
      { title: "Contact name", value: user.contact_name, short: true },
      { title: "Contact email", value: user.contact_email, short: true }
    ]
    slack_title = subject + (response[:status] == 200 ? " Sent" : " Failed")
    level = response[:status] == 200 ? "good" : "danger"
    self.send_notification_to_slack(nil, title: slack_title, level: level, fields: fields)

    response
  end
end
