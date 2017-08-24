class User
  include Authenticable
  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :member_id, :datacenter_id, :token

  def initialize(token)
    if token.present?
      payload = decode_token(token)

      @jwt = token
      @uid = payload.fetch("uid", nil)
      @name = payload.fetch("name", nil)
      @email = payload.fetch("email", nil)
      @role = payload.fetch("role", nil)
      @member_id = payload.fetch("member_id", nil)
      @datacenter_id = payload.fetch("datacenter_id", nil)
    else
      @role = "anonymous"
    end
  end

  def generate_token
    # @jwt
    payload = {
      uid: Faker::Code.unique.asin,
      name: Faker::Name.name,
      email: Faker::Internet.email,
      member_id: "TIB",
      datacenter_id: "TIB.PANGAEA",
      role: "staff_admin",
      iat: Time.now.to_i,
      exp: Time.now.to_i + 50 * 24 * 3600
    }.compact

    encode_token(payload)
  end

  # Helper method to check for admin user
  def is_admin?
    role == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["staff_admin", "staff_user"].include?(role)
  end
end
