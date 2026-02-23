# frozen_string_literal: true

class EnrichmentBatchProcessJob < ApplicationJob
  include ErrorSerializable

  queue_as :enrichment_batch_process_job

  def perform(lines, filename)
    log_prefix = "EnrichmentBatchProcessJob (#{filename})"

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
        uid = parsed_line["doi"]&.upcase
        doi = Doi.find_by(doi: uid, agency: "datacite")

        if doi.blank?
          Rails.logger.error("#{log_prefix}: Doi #{uid} does not exist")
          next
        end

        if doi.enrichment_field(parsed_line["field"]).nil?
          Rails.logger.error("#{log_prefix}: Unsupported enrichment field #{parsed_line["field"]} for DOI #{uid}")
          next
        end

        # We set the only_validate flag on the DOI model to true such that we
        # ensure that validation functions as expected when not persisting the record.
        doi.only_validate = true

        enrichment = Enrichment.new(
          filename: filename,
          doi: uid,
          contributors: parsed_line["contributors"],
          resources: parsed_line["resources"],
          field: parsed_line["field"],
          action: parsed_line["action"],
          original_value: parsed_line["originalValue"],
          enriched_value: parsed_line["enrichedValue"]
        )

        apply_error = doi.apply_enrichment(parsed_line)

        if apply_error.present?
          Rails.logger.error("#{log_prefix}: Failed to apply enrichment for DOI #{uid}, #{apply_error}")
          next
        end

        unless doi.valid?
          errors = serialize_errors(doi.errors, uid: enrichment.doi)
          Rails.logger.error("#{log_prefix}: Enrichment does not generate valid metadata: #{errors}")
          next
        end

        unless enrichment.save
          errors = enrichment.errors.full_messages.join(";")
          Rails.logger.error("#{log_prefix}: Failed to save enrichment for DOI #{uid}: #{errors}")
        end
      end
    end
  end
end
