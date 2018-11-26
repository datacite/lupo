module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "jsonlint"

  included do
    include Bolognese::MetadataUtils

    def sandbox
      !Rails.env.production?
    end

    def exists?
      aasm_state != "not_found"
    end

    def meta
      @meta || {}
    end

    def update_metadata   
      # check that input is well-formed if xml or json
      input = well_formed_xml(xml)

      # check whether input is id and we need to fetch the content
      id = normalize_id(input, sandbox: sandbox)

      if id.present?
        @from = find_from_format(id: id)

        # generate name for method to call dynamically
        hsh = @from.present? ? send("get_" + @from, id: id, sandbox: sandbox) : {}
        @string = hsh.fetch("string", nil)
      else
        @from = find_from_format(string: input)
        @string = input
      end

      # generate xml with attributes that have been set directly
      read_attrs = %w(creator contributor titles publisher publication_year types descriptions periodical sizes formats version_info language dates alternate_identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
        [a.to_sym, send(a.to_s)]
      end.to_h.compact
      meta = @from.present? ? send("read_" + @from, { string: raw, doi: doi, sandbox: sandbox }.merge(read_attrs)) : {}
      output = (@from != "datacite" || read_attrs.present?) ? datacite_xml : raw

      # generate attributes based on xml
      attrs = %w(creator contributor titles publisher publication_year types descriptions periodical sizes formats version_info language dates alternate_identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
        [a.to_sym, meta[a.to_s]]
      end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", xml: output)

      assign_attributes(attrs)
    rescue NoMethodError, ArgumentError => exception
      Bugsnag.notify(exception)
      logger = Logger.new(STDOUT)
      logger.error "Error " + exception.message + " for doi " + doi + "."
      logger.error exception
    end

    def well_formed_xml(string)
      return '' unless string.present?
  
      from_xml(string) || from_json(string)

      string
    end
  
    def from_xml(string)
      return nil unless string.start_with?('<?xml version=')

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

    # validate against DataCite schema
    def validation_errors
      kernel = schema_version.to_s.split("/").last || "kernel-4"
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

    def get_type(types, type)
      types[type]
    end

    def set_type(types, text, type)
      types[type] = text
    end
  end
end
