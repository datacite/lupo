class User
  # include jwt encode and decode
  include Authenticable

  attr_accessor :name, :uid, :email, :role_id, :jwt, :orcid, :provider_id, :client_id, :beta_tester, :allocator, :datacentre

  def initialize(token)
    if token.present?
      payload = decode_token(token)

      @jwt = token
      @uid = payload.fetch("uid", nil)
      @name = payload.fetch("name", nil)
      @email = payload.fetch("email", nil)
      @role_id = payload.fetch("role_id", nil)
      @provider_id = payload.fetch("provider_id", nil)
      @client_id = payload.fetch("client_id", nil)
      @beta_tester = payload.fetch("beta_tester", false)
    else
      @role_id = "anonymous"
    end
  end

  alias_method :orcid, :uid
  alias_method :id, :uid
  alias_method :flipper_id, :uid

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

  def allocator
    return nil unless provider_id.present?

    p = Provider.where(symbol: provider_id).first
    p.id if p.present?
  end

  def datacentre
    return nil unless client_id.present?

    c = Client.where(symbol: client_id).first
    c.id if c.present?
  end
end
