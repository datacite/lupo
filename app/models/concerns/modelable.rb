# frozen_string_literal: true

module Modelable
  extend ActiveSupport::Concern

  delegate :doi_from_url, to: :class
  delegate :orcid_as_url, to: :class
  delegate :orcid_from_url, to: :class
  delegate :orcid_url_from_identifier, to: :class
  delegate :ror_from_url, to: :class

  module ClassMethods
    def doi_from_url(url)
      if %r{\A(?:(http|https)://(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}/.+)\z}.
          match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(%r{^/}, "").downcase
      end
    end

    def orcid_as_url(orcid)
      return nil if orcid.blank?

      "https://orcid.org/#{orcid}"
    end

    def orcid_from_url(url)
      if %r{\A(?:(http|https)://(orcid.org|sandbox.orcid.org)/)(.+)\z}.match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(%r{^/}, "").upcase
      end
    end

    ORCID_ID_SHAPE = /\A\d{4}-\d{4}-\d{4}-\d{3}[\dX]\z/i

    # ORCID URL, or a bare id trusted because it matches the ORCID shape.
    # Returns nil for any other value so callers can skip it.
    # Does not use orcid_from_url: Doi overrides that with a parser that
    # accepts any URL and would turn an OSF id into an orcid.org URL.
    def orcid_url_from_identifier(value)
      return if value.blank?

      string = value.to_s.strip
      if (match = string.match(%r{\Ahttps?://(?:orcid\.org|sandbox\.orcid\.org)/([^/?#]+)}i))
        orcid_id = match[1]
        return orcid_as_url(orcid_id.upcase) if ORCID_ID_SHAPE.match?(orcid_id)
      end

      return orcid_as_url(string.upcase) if ORCID_ID_SHAPE.match?(string)

      nil
    end

    def ror_from_url(url)
      ror = Array(%r{\A(?:(http|https)://)?(ror\.org/)?(.+)}.match(url)).last
      "ror.org/#{ror}" if ror.present?
    end
  end
end
