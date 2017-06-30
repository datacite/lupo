class Datacentre < ApplicationRecord
  self.table_name = "datacentre"
  alias_attribute :allocator_id, :allocator
  alias_attribute :password_digest, :password
  # alias_method :password_digest=, :password=
  # validates_presence_of :name
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :allocator, class_name: 'Allocator', foreign_key: :allocator
  has_many :datasets
  # attr_accessor :password_digest
  # has_secure_password



  # def initialize(jwt)
  #   return false unless jwt.present?
  #   puts jwt.value
  #   # decode token using SHA-256 hash algorithm
  #   public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
  #   jwt_hsh = JWT.decode(jwt, public_key, true, { :algorithm => 'RS256' }).first
  #
  #   # check whether token has expired
  #   return false unless Time.now.to_i < jwt_hsh["exp"]
  #
  #   @jwt = jwt
  #   @symbol = jwt_hsh.fetch("symbol", nil)
  #   @role_name = jwt_hsh.fetch("role_mame", nil)
  # end
  #
  # # Helper method to check for admin user
  # def is_admin?
  #   role_name == "admin"
  # end
  #
  # # Helper method to check for admin or staff user
  # def is_admin_or_staff?
  #   ["admin", "staff"].include?(role_name)
  # end




end
