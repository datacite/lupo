# frozen_string_literal: true

class HideJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id, _options = {})
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      doi.hide
      doi.save
      Rails.logger.error "DOI hidden" + doi_id + "."
    else
      Rails.logger.error "Error hiding DOI " + doi_id + ": not found"
    end
  end
end
