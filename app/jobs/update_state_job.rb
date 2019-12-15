class UpdateStateJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(doi_id, options={})
    doi = Doi.where(doi: doi_id).first

    if doi.blank?
      Rails.logger.error "[State] Error updating state for DOI " + doi_id + ": not found"
    elsif doi.update_attributes(aasm_state: options[:state])
      Rails.logger.info "[State] Successfully updated state for DOI " + doi_id
    else
      Rails.logger.error "[State] Error updating state for DOI " + doi_id + ": " + errors.inspect
    end
  end
end