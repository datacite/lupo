# frozen_string_literal: true

class EnrichedDoisController < ApplicationController

  def show
    uid = params[:id].upcase
    doi = Doi.find_by(doi: uid, agency: "datacite")

    # Return 404 if the DOI does not exist
    raise ActiveRecord::RecordNotFound if doi.blank?

    enrichments = Enrichment.where(doi: uid).order(updated_at: :desc)

    # Return 404 if there are no enrichments for the DOI
    raise ActiveRecord::RecordNotFound if enrichments.empty?

    # Ensure validation works as expected when not persisting the record
    doi.only_validate = true
    doi.regenerate = true
    doi.skip_client_domains_validation = true
    doi.skip_schema_version_validation = true

    # Ensure we use schema version 4 for validation
    doi.schema_version = "http://datacite.org/schema/kernel-4" if doi.schema_version == "http://datacite.org/schema/kernel-3"

    # Collection of enrichments that were successfully applied to the DOI
    applied_enrichments = []

    enrichments.each do |enrichment|
      begin
        doi.apply_enrichment(enrichment)
        applied_enrichments << enrichment
      rescue => e
        next
      end
    end

    # Return 404 if zero enrichments were applied
    raise ActiveRecord::RecordNotFound if applied_enrichments.empty?

    # Return 404 if the DOI is invalid after applying enrichments.
    raise ActiveRecord::RecordNotFound if doi.invalid?

    data = DataciteDoiSerializer.new(doi).serializable_hash
    applied_enrichments_json = EnrichmentSerializer.new(applied_enrichments).serializable_hash
    data["relationships"] ||= {}
    data["relationships"]["enrichments"] = applied_enrichments_json

    render(json: data, status: :ok)
  end
end
