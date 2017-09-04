class User
  # include jwt encode and decode
  include Authenticable

  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :provider_id, :client_id, :allocator, :datacentre

  def initialize(token)
    if token.present?
      payload = decode_token(token)

      @jwt = token
      @uid = payload.fetch("uid", nil)
      @name = payload.fetch("name", nil)
      @email = payload.fetch("email", nil)
      @role = payload.fetch("role", nil)
      @provider_id = payload.fetch("provider_id", nil)
      @client_id = payload.fetch("client_id", nil)
    else
      @role = "anonymous"
    end
  end

  alias_method :orcid, :uid
  alias_method :id, :uid

  # Helper method to check for admin user
  def is_admin?
    role == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["staff_admin", "staff_user"].include?(role)
  end

  # Helper method to check for admin user
  def allocator
    Provider.find_by(symbol: @provider_id).id if @provider_id
  end

  # Helper method to check for admin user
  def datacentre
    Client.find_by(symbol: @client_id).id if @client_id
  end

  private
  def generate_token
    # @jwt
    payload = {
      uid: "Faker::Code.unique.asin",
      name: "Faker::Name.name",
      email: "sasasasa",
      provider_id: "TIB",
      client_id: "TIB.PANGAEA",
      role: "client_admin",
      iat: Time.now.to_i,
      exp: Time.now.to_i + 50 * 24 * 3600
    }.compact

    encode_token(payload)
  end
end
