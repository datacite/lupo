module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Bolognese::AuthorUtils
    include Bolognese::DataciteUtils
    include Bolognese::Writers::BibtexWriter
    include Bolognese::Writers::CiteprocWriter
    include Bolognese::Writers::CodemetaWriter
    include Bolognese::Writers::DataciteWriter
    include Bolognese::Writers::DataciteJsonWriter
    include Bolognese::Writers::JatsWriter
    include Bolognese::Writers::RdfXmlWriter
    include Bolognese::Writers::RisWriter
    include Bolognese::Writers::SchemaOrgWriter
    include Bolognese::Writers::TurtleWriter

    store :crosscite, accessors: [:author, :title, :publisher, :publication_year,
      :resource_type_general, :type, :additional_type, :description, :container_title,
      :type, :bibtex_type, :citeproc_type, :ris_type, :alternate_name, :keywords,
      :editor, :contributor, :funding, :language, :volume, :issue, :first_page, :last_page,
      :date_created, :date_published, :date_modified, :date_accepted, :date_available,
      :date_copyrighted, :date_collected, :date_submitted, :date_valid, :related_identifier,
      :is_referenced_by, :is_part_of, :has_part, :is_identical_to, :is_previous_version_of,
      :is_new_version_of, :is_supplement_to,
      :references, :license, :subject, :content_size, :spatial_coverage, :schema_version,
      :style, :locale], coder: JSON

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
        resource_type_general: resource_type_general,
        additional_type: additional_type,
        description: description,
        license: license,
        date_published: date_published
      }.compact

      bolognese = Bolognese::Metadata.new(input: Base64.decode64(value), **options)

      self.crosscite = JSON.parse(bolognese.crosscite)
      @schema_version = bolognese.schema_version || "http://datacite.org/schema/kernel-4"

      metadata.build(doi: self, xml: bolognese.datacite, namespace: @schema_version)
    end

    # xml is generated from crosscite JSON, unless
    def datacite
      datacite_xml
    end

    def xml
      datacite
    end

    def load_doi_metadata
      return nil if self.crosscite.present? || current_metadata.blank?

      bolognese = Bolognese::Metadata.new(input: current_metadata.xml,
                                          from: "datacite",
                                          doi: doi,
                                          sandbox: !Rails.env.production?)

      self.crosscite = JSON.parse(bolognese.crosscite)
    rescue ArgumentError, NoMethodError => e
      Rails.logger.error "Error for " + doi + ": " + e.message
      return nil
    end

    # def schema_version
    #   @schema_version ||= current_metadata ? current_metadata.namespace : "http://datacite.org/schema/kernel-4"
    # end

    # helper methods from bolognese below

    # validate against DataCite schema, unless draft state
    def validation_errors
      return [] if draft?

      kernel = (schema_version || "http://datacite.org/schema/kernel-4").split("/").last
      filepath = Bundler.rubygems.find_name('bolognese').first.full_gem_path + "/resources/#{kernel}/metadata.xsd"
      schema = Nokogiri::XML::Schema(open(filepath))

      schema.validate(Nokogiri::XML(xml, nil, 'UTF-8')).reduce([]) do |sum, error|
        _, _, source, title = error.to_s.split(': ').map(&:strip)
        source = source.split("}").last[0..-2]
        errors.add(source.to_sym, title)
        sum << { source: source, title: title }
        sum
      end
    rescue Nokogiri::XML::SyntaxError => e
      e.message
    end

    def validation_errors?
      validation_errors.present?
    end

    def citation
      params = { style: style, locale: locale }
      citation_url = ENV["CITEPROC_URL"] + URI.encode_www_form(params)
      response = Maremma.post citation_url, content_type: 'json', data: citeproc
      response.body.fetch("data", nil)
    end

    def reverse
      { "citation" => Array.wrap(is_referenced_by).map { |r| { "@id" => r["id"] }}.unwrap,
        "isBasedOn" => Array.wrap(is_supplement_to).map { |r| { "@id" => r["id"] }}.unwrap }.compact
    end

    def graph
      RDF::Graph.new << JSON::LD::API.toRdf(schema_hsh)
    end
  end
end
