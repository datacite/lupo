# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  included do
    def normalize_doi(doi)
      doi =
        Array(
          %r{\A(?:(http|https):/(/)?(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}/.+)\z}.
            match(doi),
        ).
          last
      # remove non-printing whitespace and downcase
      doi = doi.delete("\u200B").downcase if doi.present?

      "https://doi.org/#{doi}" if doi.present?
    end

    def get_doi_ra(prefix)
      return nil if prefix.blank?

      url = "https://doi.org/ra/#{prefix}"
      result = Maremma.get(url)

      result.body.dig("data", 0, "RA")
    end

    def validate_prefix(doi)
      Array(
        %r{\A(?:(http|https):/(/)?(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}).*\z}.
          match(doi),
      ).
        last
    end
  end

  module ClassMethods
    def get_doi_ra(prefix)
      return nil if prefix.blank?

      url = "https://doi.org/ra/#{prefix}"
      result = Maremma.get(url)

      result.body.dig("data", 0, "RA")
    end

    def validate_doi(doi)
      doi =
        Array(
          %r{\A(?:(http|https):/(/)?(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}/.+)\z}.
            match(doi),
        ).
          last
      # remove non-printing whitespace and downcase
      doi.delete("\u200B").downcase if doi.present?
    end

    def validate_prefix(doi)
      Array(
        %r{\A(?:(http|https):/(/)?(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}).*\z}.
          match(doi),
      ).
        last
    end

    def doi_from_url(url)
      if %r{\A(?:(http|https)://(dx\.)?(doi.org|handle.test.datacite.org)/)?(doi:)?(10\.\d{4,5}/.+)\z}.
          match?(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(%r{^/}, "").downcase
      end
    end
  end
end
