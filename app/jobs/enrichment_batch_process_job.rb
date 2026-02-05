# frozen_string_literal: true

class EnrichmentBatchProcessJob < ApplicationJob
  queue_as :enrichment_batch_process_job

  def perform(lines)
    log_prefix = "EnrichmentBathProcessJob"
    Rails.logger.info("#{log_prefix}: Job started")

    Parallel.each(lines, in_threads: 10) do |line|
      parsed_line = JSON.parse(line)

      doi = Doi.find_by(doi: parsed_line["doi"], agency: "datacite")

      if doi.blank?
        Rails.logger.error(
          "#{log_prefix}: Doi #{parsed_line["doi"]} does not exist")
      else
        enrichment = Enrichment.new(
          doi: parsed_line["doi"],
          contributors: parsed_line["contributors"],
          resources: parsed_line["resources"],
          field: parsed_line["field"],
          action: parsed_line["action"],
          original_value: parsed_line["originalValue"],
          enriched_value: parsed_line["enrichedValue"]
        )

        unless enrichment.save
          Rails.logger.warn(
            "#{log_prefix}: Enrichment failed to save: #{enrichment.errors.full_messages.join(";")}")
        end
      end

      Rails.logger.info("#{log_prefix}: Job completed")
    end
  end
end
