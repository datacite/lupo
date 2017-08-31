class User
  # include jwt encode and decode
  include Authenticable

  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :member_id, :datacenter_id, :allocator, :datacentre

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
    Member.find_by(symbol: @member_id).id if @member_id
  end

  # Helper method to check for admin user
  def datacentre
    Datacenter.find_by(symbol: @datacenter_id).id if @datacenter_id
  end

  private
  def generate_token
    # @jwt
    payload = {
      uid: "Faker::Code.unique.asin",
      name: "Faker::Name.name",
      email: "sasasasa",
      member_id: "TIB",
      datacenter_id: "TIB.PANGAEA",
      role: "data_center_admin",
      iat: Time.now.to_i,
      exp: Time.now.to_i + 50 * 24 * 3600
    }.compact

    encode_token(payload)
  end
end
