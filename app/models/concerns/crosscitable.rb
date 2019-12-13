module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "jsonlint"

  included do
    include Bolognese::MetadataUtils

    attr_accessor :issue, :volume, :style, :locale

    # alias_attribute :get_medra, :get_crossref
    # alias_attribute :read_medra, :read_crossref
    # alias_attribute :get_kisti, :get_crossref
    # alias_attribute :read_kisti, :read_crossref
    # alias_attribute :get_jalc, :get_crossref
    # alias_attribute :read_jalc, :read_crossref
    # alias_attribute :get_op, :get_crossref
    # alias_attribute :read_op, :read_crossref

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

      # check whether input is id and we need to fetch the content
      id = normalize_id(input, sandbox: sandbox)

      if id.present?
        from = find_from_format(id: id)

        # generate name for method to call dynamically
        hsh = from.present? ? send("get_" + from, id: id, sandbox: sandbox) : {}
        input = hsh.fetch("string", nil)
      else
        from = find_from_format(string: input)
      end

      meta = from.present? ? send("read_" + from, { string: input, doi: options[:doi], sandbox: sandbox }).compact : {}
      meta.merge("string" => input, "from" => from)
    rescue NoMethodError, ArgumentError => exception
      Raven.capture_exception(exception)

      logger = LogStashLogger.new(type: :stdout)
      logger.error "Error " + exception.message + " for doi " + @doi + "."
      logger.error exception

      {}
    end

    def replace_doi(input, options={})
      return input unless options[:doi].present?
      
      doc = Nokogiri::XML(input, nil, 'UTF-8', &:noblanks)
      node = doc.at_css("identifier")
      node.content = options[:doi].to_s.upcase if node.present? && options[:doi].present?
      doc.to_xml.strip
    end

    def update_xml
      # check whether input is id and we need to fetch the content
      id = normalize_id(xml, sandbox: sandbox)

      if id.present?
        from = find_from_format(id: id)

        # generate name for method to call dynamically
        hsh = from.present? ? send("get_" + from, id: id, sandbox: sandbox) : {}
        xml = hsh.fetch("string", nil)
      else
        from = find_from_format(string: xml)
      end

      # generate new xml if attributes have been set directly and/or from metadata that are not DataCite XML
      read_attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats version_info language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url schema_version).map do |a|
        [a.to_sym, send(a.to_s)]
      end.to_h.compact

      meta = from.present? ? send("read_" + from, { string: xml, doi: doi, sandbox: sandbox }.merge(read_attrs)) : {}
      
      xml = datacite_xml

      write_attribute(:xml, xml)
    end

    def clean_xml(string)
      begin
        return nil unless string.present?

        # enforce utf-8
        string = string.force_encoding("UTF-8")
      rescue ArgumentError, Encoding::CompatibilityError => exception
        # convert utf-16 to utf-8
        string = string.force_encoding('UTF-16').encode('UTF-8')
        string.gsub!('encoding="UTF-16"', 'encoding="UTF-8"')
      end

      # remove optional bom
      string.gsub!("\xEF\xBB\xBF", '')

      # remove leading and trailing whitespace
      string = string.strip

      # handle missing <?xml version="1.0" ?> and additional namespace
      return nil unless string.start_with?('<?xml version=') || string.start_with?('<resource ') || /\A<.+:resource/.match(string)

      # make sure xml is valid
      doc = Nokogiri::XML(string) { |config| config.strict.noblanks }
      doc.to_xml
    rescue ArgumentError, Encoding::CompatibilityError => exception
      logger = LogStashLogger.new(type: :stdout)
      logger.error "Error " + exception.message + "."
      logger.error exception

      nil
    end

    def well_formed_xml(string)
      return nil unless string.present?
  
      from_xml(string) || from_json(string)

      string
    end
  
    def from_xml(string)
      return nil unless string.start_with?('<?xml version=') || string.start_with?('<resource ')

      doc = Nokogiri::XML(string) { |config| config.strict.noblanks }
      doc.to_xml
    end
  
    def from_json(string)
      linter = JsonLint::Linter.new
      errors_array = []

      valid = linter.send(:check_not_empty?, string, errors_array)
      valid &&= linter.send(:check_syntax_valid?, string, errors_array)
      valid &&= linter.send(:check_overlapping_keys?, string, errors_array)

      raise JSON::ParserError, errors_array.join("\n") if errors_array.present?

      string
    end

    def get_content_type(string)
      return "xml" if Nokogiri::XML(string).errors.empty?

      begin
        JSON.parse(string)
        return "json"
      rescue
        "string"
      end
    end
  end
end
