module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Bolognese::DataciteUtils
    include Bolognese::Writers::DataciteWriter

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

      metadata.build(doi: self, xml: datacite_xml, namespace: schema_version)
    end

    # xml is generated from crosscite JSON
    def xml
      datacite_xml
    end

    def load_doi_metadata
      return nil if self.crosscite.present?

      input = current_metadata.present? ? current_metadata.xml : xml
      bolognese = Bolognese::Metadata.new(input: input.to_s,
                                          from: "datacite",
                                          doi: doi,
                                          sandbox: !Rails.env.production?)

      self.crosscite = JSON.parse(bolognese.crosscite)
    end
  end
end
