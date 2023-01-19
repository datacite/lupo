# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  delegate :get_doi_ra, to: :class
  delegate :validate_prefix, to: :class
  delegate :normalize_doi, to: :class
  delegate :validate_prefix, to: :class
  delegate :validate_doi, to: :class


  module ClassMethods
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
  end
end
