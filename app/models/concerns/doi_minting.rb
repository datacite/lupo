# frozen_string_literal: true

# Random DOI generation (prefix + shoulder + Base32). Shared by domain models and MDS minting.
# Depends on Bolognese::DoiUtils (#validate_prefix) being available on the including class.
module DoiMinting
  extend ActiveSupport::Concern

  require "securerandom"
  require "base32/url"

  UPPER_LIMIT = 1_073_741_823

  def generate_random_dois(str, options = {})
    prefix = validate_prefix(str)
    fail IdentifierError, "No valid prefix found" if prefix.blank?

    shoulder = str.split("/", 2)[1].to_s
    encode_doi(
      prefix,
      shoulder: shoulder, number: options[:number], size: options[:size],
    )
  end

  def encode_doi(prefix, options = {})
    return nil if prefix.blank?

    number = options[:number].to_s.scan(/\d+/).join("").to_i
    shoulder = options[:shoulder].to_s
    shoulder += "-" if shoulder.present?
    length = 8
    split = 4
    size = (options[:size] || 1).to_i

    Array.new(size).map do |_a|
      n = number.positive? ? number : SecureRandom.random_number(UPPER_LIMIT)
      prefix.to_s + "/" + shoulder +
        Base32::URL.encode(n, split: split, length: length, checksum: true)
    end.uniq
  end
end
