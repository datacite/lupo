class DeleteJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(doi_id, options={})
    logger = Logger.new(STDOUT)
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      doi.destroy
      logger.info "Deleted DOI " + doi_id + "."
    else
      logger.info "Error deleting DOI " + doi_id + ": not found"
    end
  end
end
