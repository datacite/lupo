# frozen_string_literal: true

class DeleteJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id, _options = {})
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      doi.destroy
      Rails.logger.info "Deleted DOI " + doi_id + "."
    else
      Rails.logger.error "Error deleting DOI " + doi_id + ": not found"
    end
  end
end
