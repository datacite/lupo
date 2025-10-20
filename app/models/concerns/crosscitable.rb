# frozen_string_literal: true

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

    def parse_xml(input, options = {})
      return {} if input.blank?

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

      meta =
        if from.present?
          send(
            "read_" + from,
            string: input, doi: options[:doi], sandbox: sandbox,
          ).
            compact
        else
          {}
        end
      meta.merge("string" => input, "from" => from)
    rescue NoMethodError, ArgumentError => e
      Sentry.capture_exception(e)

      Rails.logger.error "Error " + e.message.to_s + " for doi " + @doi.to_s +
        "."
      Rails.logger.error e.inspect

      {}
    end

    def replace_doi(input, options = {})
      return input if options[:doi].blank?

      doc = Nokogiri.XML(input, nil, "UTF-8", &:noblanks)
      node = doc.at_css("identifier")
      if node.present? && options[:doi].present?
        node.content = options[:doi].to_s.upcase
      end
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
      read_attrs =
        %w[
          creators
          contributors
          titles
          publisher
          publication_year
          types
          descriptions
          container
          sizes
          formats
          version_info
          language
          dates
          identifiers
          related_identifiers
          related_items
          funding_references
          geo_locations
          rights_list
          subjects
          content_url
          schema_version
        ].map { |a| [a.to_sym, send(a.to_s)] }.to_h.
          compact

      if from.present?
        send(
          "read_#{from}".to_sym,
          **{ string: xml, doi: doi, sandbox: sandbox }.merge(read_attrs),
        )
      else
        {}
      end

      xml = datacite_xml

      write_attribute(:xml, xml)
    end

    def clean_xml(string)
      begin
        return nil if string.blank?

        # enforce utf-8
        string = string.force_encoding("UTF-8")
      rescue ArgumentError, Encoding::CompatibilityError
        # convert utf-16 to utf-8
        string = string.force_encoding("UTF-16").encode("UTF-8")
        string.gsub!("encoding=\"UTF-16\"", "encoding=\"UTF-8\"")
      end

      # remove optional bom
      string.gsub!("\xEF\xBB\xBF", "")

      # remove leading and trailing whitespace
      string = string.strip

      # handle missing <?xml version="1.0" ?> and additional namespace
      unless string.start_with?("<?xml version=", "<resource ") ||
          /\A<.+:resource/.match(string)
        return nil
      end

      # make sure xml is valid
      doc = Nokogiri.XML(string) { |config| config.strict.noblanks }
      doc.to_xml
    rescue ArgumentError, Encoding::CompatibilityError => e
      Rails.logger.error "Error " + e.message + "."
      Rails.logger.error e

      nil
    end

    def well_formed_xml(string)
      return nil if string.blank?

      from_xml(string) || from_json(string)

      string
    end

    def from_xml(string)
      return nil unless string.start_with?("<?xml version=", "<resource ")

      doc = Nokogiri.XML(string) { |config| config.strict.noblanks }
      doc.to_xml
    end

    def from_json(string)
      linter = JsonLint::Linter.new
      errors_array = []

      valid = linter.send(:check_not_empty?, string, errors_array)
      valid &&= linter.send(:check_syntax_valid?, string, errors_array)
      valid && linter.send(:check_overlapping_keys?, string, errors_array)

      raise JSON::ParserError, errors_array.join("\n") if errors_array.present?

      string
    end

    def get_content_type(string)
      return "xml" if Nokogiri.XML(string).errors.empty?

      begin
        JSON.parse(string)
        "json"
      rescue StandardError
        "string"
      end
    end
  end
end
