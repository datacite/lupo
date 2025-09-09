# frozen_string_literal: true

class MigrateMetadataXmlJob < ApplicationJob
  queue_as :lupo_support

  def perform(id)
    Metadata.migrate_xml_by_id(id)
  end
end
