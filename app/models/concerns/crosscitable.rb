module Crosscitable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"
  require "jsonlint"

  included do
    include Bolognese::MetadataUtils

    # track changes of virtual attributes

    def author=(value)
      return @author if value.blank? || value == author

      attribute_will_change!(:author)
      @author = value
    end

    def title=(value)
      return @title if value.nil? || value == title
      
      attribute_will_change!(:title)
      @title = value
    end

    def publisher=(value)
      return @publisher if value.nil? || value == publisher

      attribute_will_change!(:publisher)
      @publisher = value
    end

    def date_published=(value)
      return @date_published if value.nil? || value == date_published

      attribute_will_change!(:date_published)
      @date_published = value
    end

    def additional_type=(value)
      return @additional_type if value.nil? || value == additional_type

      attribute_will_change!(:additional_type)
      @additional_type = value
    end

    def resource_type_general=(value)
      return @resource_type_general if value.nil? || value == resource_type_general

      attribute_will_change!(:resource_type_general)
      @resource_type_general = value
    end

    def description=(value)
      return @description if value.nil? || value == description

      attribute_will_change!(:description)
      @description = value
    end

    # modified bolognese attributes

    def sandbox
      !Rails.env.production?
    end

    # cache doi metadata
    def meta
      @meta ||= fetch_cached_meta
    end

    def exists?
      meta.fetch("state", "not_found") != "not_found"
    end

    # default to DataCite schema 4
    def schema_version
      @schema_version ||= meta.fetch("schema_version", nil) || "http://datacite.org/schema/kernel-4"
    end

    # cache xml
    def xml
      @xml ||= fetch_cached_xml
    end

    def xml=(value)
      # check that input is well-formed if xml or json
      input = well_formed_xml(value)

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

      @xml = @string.present? ? datacite : nil
      attribute_will_change!(:xml)
    rescue NoMethodError, ArgumentError => exception
      Bugsnag.notify(exception)
      Rails.logger.error "Error " + exception.message + " for doi " + doi + "."
      @xml = nil
    end

    def well_formed_xml(string)
      return '' unless string.present?

      string = Base64.decode64(string).force_encoding("UTF-8")
  
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
      kernel = schema_version.split("/").last
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
  end
end
