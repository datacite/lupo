class User
  attr_accessor :name, :uid, :email, :role, :jwt, :orcid

  def initialize(jwt)
    return false unless jwt.present?

    # decode token using SHA-256 hash algorithm
    public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    jwt_hsh = JWT.decode(jwt, public_key, true, { :algorithm => 'RS256' }).first

    # check whether token has expired
    return false unless Time.now.to_i < jwt_hsh["exp"]

    @jwt = jwt
    @uid = jwt_hsh.fetch("uid", nil)
    @name = jwt_hsh.fetch("name", nil)
    @email = jwt_hsh.fetch("email", nil)
    @role = jwt_hsh.fetch("role", nil)
  end

  alias_method :orcid, :uid
  alias_method :id, :uid

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end
end
