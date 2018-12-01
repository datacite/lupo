module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "jsonlint"

  included do
    include Bolognese::MetadataUtils

    attr_accessor :issue, :volume, :style, :locale

    def sandbox
      !Rails.env.production?
    end

    def exists?
      aasm_state != "not_found"
    end

    def meta
      @meta || {}
    end

    def parse_xml(input, options={})
      return {} unless input.present?

      # detect metadata format
      from = find_from_format(string: input)

      if from.nil?
        # check whether input is valid id and we need to fetch the content
        id = normalize_id(input, sandbox: sandbox)
        from = find_from_format(id: id)

        # generate name for method to call dynamically
        hsh = from.present? ? send("get_" + from, id: id, sandbox: sandbox) : {}
        input = hsh.fetch("string", nil)        
      end

      meta = from.present? ? send("read_" + from, { string: input, doi: options[:doi], sandbox: sandbox }).compact : {}
      meta.merge("string" => input, "from" => from)
    rescue NoMethodError, ArgumentError => exception
      Bugsnag.notify(exception)
      logger = Logger.new(STDOUT)
      logger.error "Error " + exception.message + " for doi " + doi + "."
      logger.error exception

      {}
    end

    def replace_doi(input, options={})
      doc = Nokogiri::XML(input, nil, 'UTF-8', &:noblanks)
      node = doc.at_css("identifier")
      node.content = options[:doi].to_s.upcase if node.present? && options[:doi].present?
      doc.to_xml.strip
    end

    def update_xml
      if regenerate
        # detect metadata format
        from = find_from_format(string: xml)

        if from.nil?
          # check whether input is valid id and we need to fetch the content
          id = normalize_id(xml, sandbox: sandbox)
          from = find_from_format(id: id)

          # generate name for method to call dynamically
          hsh = from.present? ? send("get_" + from, id: id, sandbox: sandbox) : {}
          xml = hsh.fetch("string", nil)        
        end

        # generate new xml if attributes have been set directly and/or from metadata are not DataCite XML
        read_attrs = %w(creators contributors titles publisher publication_year types descriptions periodical sizes formats version_info language dates alternate_identifiers related_identifiers funding_references geo_locations rights_list subjects content_url schema_version).map do |a|
          [a.to_sym, send(a.to_s)]
        end.to_h.compact

        meta = from.present? ? send("read_" + from, { string: xml, doi: doi, sandbox: sandbox }.merge(read_attrs)) : {}
        xml = datacite_xml
      end

      write_attribute(:xml, xml)
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
  end
end
