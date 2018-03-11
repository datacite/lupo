module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Bolognese::DataciteUtils

    store :crosscite, accessors: [:author, :title, :publisher, :publication_year,
      :resource_type_general, :type, :additional_type, :description, :container_title, :type,
      :alternate_name, :keywords, :editor, :funding, :date_created, :date_published,
      :date_modified, :related_identifier, :license, :subject, :schema_version], coder: JSON

    attr_accessor :regenerate

    def xml=(value)
      return nil unless value.present?

      options = {
        doi: doi,
        sandbox: !Rails.env.production?,
        regenerate: false,
        author: author,
        title: title,
        publisher: publisher,
        publication_year: publication_year,
        resource_type_general: resource_type_general,
        additional_type: additional_type,
        description: description,
        license: license,
        date_published: date_published
      }.compact

      bolognese = Bolognese::Metadata.new(input: Base64.decode64(value), **options)

      self.crosscite = JSON.parse(bolognese.crosscite)
      namespace = bolognese.schema_version || "http://datacite.org/schema/kernel-4"

      metadata.build(doi: self, xml: bolognese.datacite, namespace: namespace)
    end

    # xml is generated from crosscite JSON
    def xml
      datacite_xml
    end

    def load_doi_metadata
      return nil if self.crosscite.present? || current_metadata.blank?

      bolognese = Bolognese::Metadata.new(input: current_metadata.xml,
                                          from: "datacite",
                                          doi: doi,
                                          sandbox: !Rails.env.production?)

      self.crosscite = JSON.parse(bolognese.crosscite)
    end
  end
end
