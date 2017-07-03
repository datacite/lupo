class User
  ROLES = %i[admin superadmin staff user banned guest]
  attr_accessor :name, :uid, :email, :role, :jwt, :orcid, :symbol

  def initialize(jwt)
    return false unless jwt.present?

    @uid = jwt[:uid]
    @name = jwt[:name]
    @email = jwt[:email]
    @role = jwt[:role]
    @orcid = jwt[:orcid]
    @symbol = jwt[:symbol]
    @jwt = jwt

  end

  # Helper method to check for admin user
  def is_member_admin?
    role == "member_admin"
  end  # Helper method to check for admin user

  def is_datacentre_admin?
    role == "datacentre"
  end  # Helper method to check for admin user

  def is_staff_admin?
    role == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end
end
