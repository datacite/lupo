# frozen_string_literal: true

module Rorable
  extend ActiveSupport::Concern

  def get_ror_from_crossref_funder_id(funder_id)
    funder_id_suffix = funder_id.split("10.13039/").last
    FUNDER_TO_ROR[funder_id_suffix]
  end

  def get_ror_parents(ror_id)
    normalized_ror = "https://#{ror_from_url(ror_id)}"
    ROR_HIERARCHY[normalized_ror]&.fetch("ancestors", []) || []
  end

  def get_countries_from_ror(ror_id)
    normalized_ror = ror_from_url(ror_id)
    return [] if normalized_ror.blank?

    normalized_ror = "https://#{normalized_ror}" unless normalized_ror.start_with?("https://")

    countries = ROR_TO_COUNTRIES[normalized_ror]
    Array.wrap(countries).map(&:upcase).uniq
  end
end
