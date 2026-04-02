# frozen_string_literal: true

class EnrichedDoisController < ApplicationController

  def show
    uid = params[:id].upcase
    doi = Doi.includes(:enrichments).find_by(doi: uid, agency: "datacite")

    # Return 404 if the DOI does not exist
    raise ActiveRecord::RecordNotFound if doi.blank?

    # Return 404 if there are no enrichments for the DOI
    raise ActiveRecord::RecordNotFound if doi.enrichments.empty?

    # Ensure validation works as expected when not persisting the record
    doi.only_validate = true
    doi.regenerate = true
    doi.skip_client_domains_validation = true
    doi.skip_schema_version_validation = true

    # Ensure we use schema version 4 for validation
    doi.schema_version = "http://datacite.org/schema/kernel-4" if doi.schema_version == "http://datacite.org/schema/kernel-3"

    doi.enrichments.each do |enrichment|
      begin
        doi.apply_enrichment(enrichment)
      rescue => e
        next
      end
    end

    # Return 404 if the DOI is invalid after applying enrichments.
    raise ActiveRecord::RecordNotFound if doi.invalid?

    render(json: EnrichedDoiSerializer.new(doi).serializable_hash, status: :ok)
  end
end
