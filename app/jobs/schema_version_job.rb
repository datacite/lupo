class SchemaVersionJob < ActiveJob::Base
  queue_as :lupo_background

  include Crosscitable

  def perform(ids, options = {})
    ids.each do |id|
      doi = Doi.where(doi: id, schema_version: nil).first
      xml = doi.xml
      metadata = xml.present? ? parse_xml(xml, doi: id) : {}

      if doi.blank? || metadata["schema_version"].blank?
        Rails.logger.error "[SchemaVersion] Error updating schema_version for DOI " + id + ": not found"
      elsif doi.update(schema_version: metadata["schema_version"])
        Rails.logger.info "[SchemaVersion] Successfully updated schema_version for DOI " + id
      else
        Rails.logger.error "[SchemaVersion] Error updating schema_version for DOI " + id + ": " + errors.inspect
      end
    end
  end
end
