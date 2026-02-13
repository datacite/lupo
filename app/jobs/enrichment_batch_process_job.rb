# frozen_string_literal: true

class EnrichmentBatchProcessJob < ApplicationJob
  include ErrorSerializable

  queue_as :enrichment_batch_process_job

  def perform(lines)
    log_prefix = "EnrichmentBatchProcessJob"

    # We will process the lines in parallel to speed up ingestion.
    Parallel.each(lines, in_threads: 10) do |line|
      parsed_line = JSON.parse(line)

      # We only create enrichments for DOIs that exist and which have an agency of 'datacite'.
      doi = Doi.find_by(doi: parsed_line["doi"], agency: "datacite")

      if doi.blank?
        Rails.logger.error("#{log_prefix}: Doi #{parsed_line["doi"]} does not exist")
        next
      end

      # We set the only_validate flag on the DOI model to true such that we
      # ensure that validation functions as expected when not persisting the record.
      doi.only_validate = true

      enrichment = Enrichment.new(
        doi: "#{parsed_line["doi"]}",
        contributors: parsed_line["contributors"],
        resources: parsed_line["resources"],
        field: parsed_line["field"],
        action: parsed_line["action"],
        original_value: parsed_line["originalValue"],
        enriched_value: parsed_line["enrichedValue"]
      )

      doi.apply_enrichment(enrichment)

      unless doi.valid?
        errors = serialize_errors(doi.errors, uid: enrichment.doi)
        Rails.logger.error("#{log_prefix}: Enrichment does not generate valid metadata: #{errors}")
        next
      end

      unless enrichment.save
        errors = enrichment.errors.full_messages.join(";")
        Rails.logger.error("#{log_prefix}: Enrichment failed to save: #{errors}")
      end
    end
  end

  # def enrich_doi(enrichment, doi)
  #   action = enrichment["action"]
  #   field = enrichment["field"].underscore

  #   case action
  #   when "insert"
  #     doi[field] ||= []
  #     doi[field] << enrichment["enriched_value"]
  #   when "update"
  #     doi[field] = enrichment["enriched_value"]
  #   when "update_child"
  #     doi[field].each_with_index do |item, index|
  #       if item == enrichment["original_value"]
  #         doi[field][index] = enrichment["enriched_value"]
  #       end
  #     end
  #   when "delete_child"
  #     doi[field] ||= []
  #     doi[field].each_with_index do |item, index|
  #       if item == enrichment["original_value"]
  #         doi[field].delete_at(index)
  #         break
  #       end
  #     end
  #   end
  # end
end
