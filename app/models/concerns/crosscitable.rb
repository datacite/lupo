module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils
    include Bolognese::AuthorUtils
    include Bolognese::DateUtils
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

    store :crosscite, accessors: [:author, :title, :publisher, :service_provider,
      :resource_type_general, :type, :additional_type, :description,
      :type, :bibtex_type, :citeproc_type, :ris_type, :alternate_name, :keywords,
      :editor, :contributor, :funding, :language, :volume, :issue, :first_page, :last_page,
      :date_created, :date_published, :date_modified, :date_accepted, :date_available,
      :date_copyrighted, :date_collected, :date_submitted, :date_valid,
      :is_referenced_by, :is_part_of, :has_part, :is_identical_to, :is_previous_version_of,
      :is_new_version_of, :is_supplement_to, :is_supplemented_by, :references,
      :reviews, :is_reviewed_by, :is_identical_to, :is_variant_form_of, :is_original_form_of,
      :license, :subject,
      :content_size, :spatial_coverage, :schema_version],
      coder: JSON

    attr_accessor :regenerate, :raw, :from, :style, :locale

    # calculated attributes from bolognese

    def related_identifier_hsh(relation_type)
      Array.wrap(send(relation_type)).select { |r| r["id"] || r["issn"] }
        .map { |r| r.merge("relationType" => relation_type.camelize) }
    end

    def related_identifier
      relation_types = %w(is_part_of has_part references is_referenced_by is_supplement_to is_supplemented_by)
      relation_types.reduce([]) { |sum, r| sum += related_identifier_hsh(r) }
    end

    def publication_year
      date_published.present? ? date_published[0..3].to_i.presence : nil
    end

    def container_title
      Array.wrap(is_part_of).length == 1 ? is_part_of.to_h.fetch("title", nil) : nil
    end

    def should_passthru
      (from == "datacite") && !regenerate
    end

    def style
      @style ||= "apa"
    end

    def locale
      @locale ||= "en-US"
    end

    # xml is generated from crosscite JSON unless passed through
    def datacite
      should_passthru ? raw : datacite_xml
    end

    def xml
      datacite
    end

    def xml=(value)
      return nil unless value.present?

      options = {
        doi: doi,
        sandbox: !Rails.env.production?,
        regenerate: false,
        url: url,
        author: author,
        title: title,
        publisher: publisher,
        date_published: date_published,
        resource_type_general: resource_type_general,
        additional_type: additional_type,
        description: description,
        license: license
      }.compact

      bolognese = Bolognese::Metadata.new(input: Base64.decode64(value), **options)

      self.crosscite = JSON.parse(bolognese.crosscite)
      @schema_version = bolognese.schema_version || "http://datacite.org/schema/kernel-4"
      @from = bolognese.from
      @raw = bolognese.raw

      metadata.build(doi: self, xml: datacite, namespace: @schema_version)
    end

    def schema_version
      @schema_version ||= current_metadata ? current_metadata.namespace : "http://datacite.org/schema/kernel-4"
    end

    def load_doi_metadata
      return nil if self.crosscite.present? || current_metadata.blank?

      self.crosscite = cached_doi_response
      #@from = bolognese.from
      #@raw = bolognese.raw
    end

    # helper methods from bolognese below

    # validate against DataCite schema
    def validation_errors
      kernel = (schema_version || "http://datacite.org/schema/kernel-4").split("/").last
      filepath = Bundler.rubygems.find_name('bolognese').first.full_gem_path + "/resources/#{kernel}/metadata.xsd"
      schema = Nokogiri::XML::Schema(open(filepath))

      schema.validate(Nokogiri::XML(xml, nil, 'UTF-8')).reduce([]) do |sum, error|
        _, _, source, title = error.to_s.split(': ').map(&:strip)
        source = source.split("}").last[0..-2]

        # only add to errors if not in draft state
        errors.add(source.to_sym, title) unless draft?

        sum << { source: source, title: title }
        sum
      end
    rescue Nokogiri::XML::SyntaxError => e
      e.message
    end

    def validation_errors?
      validation_errors.present?
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
