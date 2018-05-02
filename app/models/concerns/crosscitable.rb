module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"
  require "jsonlint"

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

    # store :crosscite, accessors: [:author, :title, :publisher, :service_provider,
    #   :resource_type_general, :type, :additional_type, :description,
    #   :type, :bibtex_type, :citeproc_type, :ris_type, :alternate_name, :keywords,
    #   :editor, :contributor, :funding, :language, :volume, :issue, :first_page, :last_page,
    #   :date_created, :date_published, :date_modified, :date_accepted, :date_available,
    #   :date_copyrighted, :date_collected, :date_submitted, :date_valid,
    #   :is_referenced_by, :is_part_of, :has_part, :is_identical_to, :is_previous_version_of,
    #   :is_new_version_of, :is_supplement_to, :is_supplemented_by, :references,
    #   :reviews, :is_reviewed_by, :is_identical_to, :is_variant_form_of, :is_original_form_of,
    #   :license, :subject, :b_url, :b_version,
    #   :content_size, :spatial_coverage, :schema_version],
    #   coder: JSON

    def crosscite
      cached_doi_response
    end

    def type
      crosscite["type"] if crosscite.present?
    end

    def additional_type
      @additional_type ||= crosscite.to_h["additional_type"]
    end

    def additional_type=(value)
      @additional_type = value
    end

    def bibtex_type
      crosscite["bibtex_type"] if crosscite.present?
    end

    def ris_type
      crosscite["ris_type"] if crosscite.present?
    end

    def citeproc_type
      crosscite["citeproc_type"] if crosscite.present?
    end

    def resource_type_general
      @resource_type_general ||= crosscite.to_h["resource_type_general"]
    end

    def resource_type_general=(value)
      @resource_type_general = value
    end

    def alternate_name
      crosscite["alternate_name"] if crosscite.present?
    end

    def author
      @author ||= crosscite.to_h["author"]
    end

    def author=(value)
      @author = value
    end

    def editor
      crosscite["editor"] if crosscite.present?
    end

    def contributor
      crosscite["contributor"] if crosscite.present?
    end

    def title
      @title ||= crosscite.to_h["title"]
    end

    def title=(value)
      @title = value
    end

    def publisher
      @publisher ||= crosscite.to_h["publisher"]
    end

    def publisher=(value)
      @publisher = value
    end

    def date_published
      @date_published ||= crosscite.to_h["date_published"]
    end

    def date_published=(value)
      @date_published = value
    end

    def date_created
      crosscite["date_created"] if crosscite.present?
    end

    def date_modified
      crosscite["date_modified"] if crosscite.present?
    end

    def date_accepted
      crosscite["date_accepted"] if crosscite.present?
    end

    def date_available
      crosscite["date_available"] if crosscite.present?
    end

    def date_copyrighted
      crosscite["date_copyrighted"] if crosscite.present?
    end

    def date_collected
      crosscite["date_collected"] if crosscite.present?
    end

    def date_submitted
      crosscite["date_submitted"] if crosscite.present?
    end

    def date_valid
      crosscite["date_valid"] if crosscite.present?
    end

    def description
      @description ||= crosscite.to_h["description"]
    end

    def description=(value)
      @description = value
    end

    def keywords
      crosscite["keywords"] if crosscite.present?
    end

    def language
      crosscite["language"] if crosscite.present?
    end

    def license
      crosscite["license"] if crosscite.present?
    end

    def volume
      crosscite["volume"] if crosscite.present?
    end

    def issue
      crosscite["issue"] if crosscite.present?
    end

    def first_page
      crosscite["first_page"] if crosscite.present?
    end

    def last_page
      crosscite["last_page"] if crosscite.present?
    end

    def content_size
      crosscite["content_size"] if crosscite.present?
    end

    def spatial_coverage
      crosscite["spatial_coverage"] if crosscite.present?
    end

    def schema_version
      @schema_version ||= crosscite.to_h["schema_version"]
    end

    def schema_version=(value)
      @schema_version = value
    end

    def b_url
      crosscite["b_url"] if crosscite.present?
    end

    def b_version
      crosscite["b_version"] if crosscite.present?
    end

    def is_part_of
      crosscite["is_part_of"] if crosscite.present?
    end

    def has_part
      crosscite["has_part"] if crosscite.present?
    end

    def is_identical_to
      crosscite["is_identical_to"] if crosscite.present?
    end

    def is_previous_version_of
      crosscite["is_previous_version_of"] if crosscite.present?
    end

    def is_new_version_of
      crosscite["is_new_version_of"] if crosscite.present?
    end

    def references
      crosscite["references"] if crosscite.present?
    end

    def is_referenced_by
      crosscite["is_referenced_by"] if crosscite.present?
    end

    def is_supplement_to
      crosscite["is_supplement_to"] if crosscite.present?
    end

    def is_supplemented_by
      crosscite["is_supplemented_by"] if crosscite.present?
    end

    def reviews
      crosscite["reviews"] if crosscite.present?
    end

    def is_reviewed_by
      crosscite["is_reviewed_by"] if crosscite.present?
    end

    def is_variant_form_of
      crosscite["is_variant_form_of"] if crosscite.present?
    end

    def is_original_form_of
      crosscite["is_original_form_of"] if crosscite.present?
    end

    def funding
      crosscite["funding"] if crosscite.present?
    end

    def service_provider
      crosscite["service_provider"] if crosscite.present?
    end

    attr_accessor :style, :locale

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
      Array.wrap(is_part_of).first.to_h.fetch("title", nil)
    end

    def style
      @style ||= "apa"
    end

    def locale
      @locale ||= "en-US"
    end

    def datacite
      #(from == "datacite") ? fetch_cached_xml : datacite_xml
      fetch_cached_xml
    end

    def xml
      datacite
    end

    def xml=(value)
      input = well_formed_xml(value)

      options = {
        doi: doi,
        sandbox: !Rails.env.production?,
        author: author.presence,
        title: title,
        publisher: publisher,
        date_published: date_published,
        resource_type_general: resource_type_general,
        additional_type: additional_type,
        description: description
      }.compact

      bolognese = Bolognese::Metadata.new(input: input, **options)

      self.url = bolognese.b_url if url.blank?
      # self.crosscite = JSON.parse(bolognese.crosscite)
      # self.from = bolognese.from

      # add schema_version when converting from different metadata format
      schema_version = bolognese.schema_version || "http://datacite.org/schema/kernel-4"
      cached_xml = bolognese.datacite

      write_cached_xml(cached_xml)
      write_cached_schema_version(schema_version)
      
      metadata.build(doi: self, xml: cached_xml, namespace: schema_version)
    rescue NoMethodError, ArgumentError => exception
      Bugsnag.notify(exception)
      Rails.logger.error "Error " + exception.message + " for doi " + doi + "."
      nil
    end

    def schema_version
      fetch_cached_schema_version
    end

    # def load_doi_metadata
    #   return nil if self.crosscite.present? || current_metadata.blank?

    #   self.crosscite = cached_doi_response
    # end

    def well_formed_xml(string)
      return "" unless string.present?

      string = Base64.decode64(string).force_encoding("UTF-8")
  
      from_xml(string) || from_json(string)

      string
    end
  
    def from_xml(string)
      return nil unless string.start_with?('<?xml version="1.0"')

      Nokogiri::XML(string) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }

      nil
    rescue Nokogiri::XML::SyntaxError => e
      line, column, level, text = e.message.split(":", 4)
      message = text.strip + " at line #{line}, column #{column}"
      errors.add(:xml, message)

      string
    end
  
    def from_json(string)
      return nil unless string.start_with?('[', '{')

      linter = JsonLint::Linter.new
      errors_array = []

      valid = linter.send(:check_not_empty?, string, errors_array)
      valid &&= linter.send(:check_syntax_valid?, string, errors_array)
      valid &&= linter.send(:check_overlapping_keys?, string, errors_array)

      errors_array.each { |e| errors.add(:xml, e.capitalize) }
      errors_array.empty? ? nil : string
    end

    # helper methods from bolognese below

    # validate against DataCite schema
    def validation_errors
      kernel = (schema_version || "http://datacite.org/schema/kernel-4").split("/").last
      filepath = Bundler.rubygems.find_name('bolognese').first.full_gem_path + "/resources/#{kernel}/metadata.xsd"
      schema = Nokogiri::XML::Schema(open(filepath))

      schema.validate(Nokogiri::XML(xml, nil, 'UTF-8')).reduce({}) do |sum, error|
        location, level, source, text = error.message.split(": ", 4)
        line, column = location.split(":", 2)
        title = text.to_s.strip + " at line #{line}, column #{column}" if line.present?
        source = source.split("}").last[0..-2] if line.present?

        errors.add(source.to_sym, title)

        sum[source.to_sym] = Array(sum[source.to_sym]) + [title]

        sum
      end
    rescue Nokogiri::XML::SyntaxError => e
      line, column, level, text = e.message.split(":", 4)
      message = text.strip + " at line #{line}, column #{column}"
      errors.add(:xml, message)

      errors
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
