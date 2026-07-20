class ApiKey < ApplicationRecord
  include Passwordable

  attr_accessor :key

  belongs_to :client, touch: true

  # Used by ApiKeySerializer belongs_to :client (id_method_name: :symbol)
  # so relationship linkage IDs are client symbols (e.g. DATACITE.TESTKEY).
  delegate :symbol, to: :client, allow_nil: true

  validates_presence_of :client, :name

  before_create :initialize_api_key

  scope :active, -> { where(revoked_at: nil) }

  def revoke!
    update!(revoked_at: Time.zone.now)
  end

  def revoked?
    revoked_at != nil
  end

  def self.authenticate(token)
    return nil if token.blank?

    prefix = token.to_s[0, 11]
    candidates = active.where(key_prefix: prefix)

    candidates.find do |api_key|
      secure_compare(api_key.key_hash, api_key.encrypt_password_sha256(token))
    end
  end

  private
    def initialize_api_key
      generate_id
      generate_key
    end

    def generate_id
      self.id ||= SecureRandom.uuid
    end

    def generate_key
      prefix = "DC."
      secret = SecureRandom.alphanumeric(32)
      plain = prefix + secret

      self.key = plain
      self.key_prefix = prefix + secret[0, 8]
      self.key_hash = encrypt_password_sha256(plain)
    end
end
