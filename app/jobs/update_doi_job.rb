class UpdateDoiJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id, _options = {})
    doi = Doi.where(doi: doi_id).first

    if doi.blank?
      Rails.logger.error "[UpdateDoi] Error updating DOI " + doi_id + ": not found"
    elsif doi.update(version: doi.version.to_i + 1)
      Rails.logger.debug "[UpdateDoi] Successfully updated DOI " + doi_id
    else
      Rails.logger.error "[UpdateDoi] Error updating DOI " + doi_id + ": " + doi.errors.messages.inspect
    end
  end
end
