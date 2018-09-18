class TransferJob < ActiveJob::Base
  queue_as :lupo_background

  def perform(doi_id, options={})
    logger = Logger.new(STDOUT)
    doi = Doi.where(doi: doi_id).first

    if doi.blank?
      logger.info "[Transfer] Error transferring DOI " + doi_id + ": not found"
    elsif doi.update_attributes(datacentre: options[:target_id])
      logger.info "[Transfer] Successfully transferred DOI " + doi_id
    else
      logger.info "[Transfer] Error transferring DOI " + doi_id + ": " + errors.inspect
    end
  end
end