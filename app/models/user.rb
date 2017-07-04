class User
  # include jwt encode and decode
  ROLES = %i[admin superadmin staff user banned guest]
  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :symbol

  include Authenticable

  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :member_id, :datacenter_id

  def initialize(token)
    payload = decode_token(token)

    @jwt = token
    @uid = payload.fetch("uid", nil)
    @name = payload.fetch("name", nil)
    @email = payload.fetch("email", nil)
    @role = payload.fetch("role", nil)
    @member_id = payload.fetch("member_id", nil)
    @datacenter_id = payload.fetch("datacenter_id", nil)

    # @uid = jwt[:uid]
    # @name = jwt[:name]
    # @email = jwt[:email]
    # @role = jwt[:role]
    # @orcid = jwt[:orcid]
    # @symbol = jwt[:symbol]
    # @jwt = jwt

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
