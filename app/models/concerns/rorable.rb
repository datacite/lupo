# frozen_string_literal: true

module Rorable
  extend ActiveSupport::Concern

  def get_ror_from_crossref_funder_id(funder_id)
    funder_id_suffix = funder_id.split("10.13039/").last
    RorReferenceStore.funder_to_ror(funder_id_suffix)
  end

  def get_ror_parents(ror_id)
    normalized_ror = "https://#{ror_from_url(ror_id)}"
    hierarchy = RorReferenceStore.ror_hierarchy(normalized_ror)
    hierarchy&.dig("ancestors") || []
  end
end
