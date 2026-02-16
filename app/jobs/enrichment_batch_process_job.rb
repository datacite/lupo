# frozen_string_literal: true

class EnrichmentBatchProcessJob < ApplicationJob
  include ErrorSerializable

  queue_as :enrichment_batch_process_job

  def perform(lines, file_name)
    log_prefix = "EnrichmentBatchProcessJob (#{file_name})"

    # We will process the lines in parallel to speed up ingestion.
    Parallel.each(lines, in_threads: 5) do |line|
      # with_connection ensures the connection is explicitly checked out and returned to the pool after
      # each iteration, preventing connection pool exhaustion.
      ActiveRecord::Base.connection_pool.with_connection do
        begin
          parsed_line = JSON.parse(line)
        rescue JSON::ParserError => e
          Rails.logger.error("#{log_prefix}: Failed to parse line: #{e.message}")
          next
        end

        # We only create enrichments for DOIs that exist and which have an agency of 'datacite'.
        doi = Doi.find_by(doi: parsed_line["doi"], agency: "datacite")

        if doi.blank?
          Rails.logger.error("#{log_prefix}: Doi #{parsed_line["doi"]} does not exist")
          next
        end

        if doi.enrichment_field(parsed_line["field"]).nil?
          Rails.logger.error("#{log_prefix}: Unsupported enrichment field #{parsed_line["field"]} for DOI #{parsed_line["doi"]}")
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
  end
end
