class AffiliationJob < ApplicationJob
  queue_as :lupo_background

  def perform(doi_id)
    doi = Doi.where(doi: doi_id).first

    if doi.present?
      new_creators = Array.wrap(doi.creators).map do |c|
        c["affiliation"] = { "name" => c["affiliation"] } if c["affiliation"].is_a?(String)
        c
      end
      new_contributors = Array.wrap(doi.contributors).map do |c|
        c["affiliation"] = { "name" => c["affiliation"] } if c["affiliation"].is_a?(String)
        c
      end
      doi.update(creators: new_creators, contributors: new_contributors)

      doi.__elasticsearch__.index_document
    else
      Rails.logger.error "[Affiliation] Error updating DOI " + doi_id + ": not found"
    end
  end
end
