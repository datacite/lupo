# frozen_string_literal: true

class XmlSchemaValidator < ActiveModel::EachValidator
  # mapping of DataCite schema properties to database fields
  def schema_attributes(el)
    schema = {
      "date" => "dates",
      "publicationYear" => "publication_year",
      "alternateIdentifiers" => "identifiers",
      "relatedIdentifiers" => "related_identifiers",
      "relatedItems" => "related_items",
      "geoLocations" => "geo_locations",
      "rightsList" => "rights_list",
      "fundingReferences" => "funding_references",
      "version" => "version_info",
      "resource" => "xml",
    }

    schema[el] || el
  end

  def get_valid_kernel(sv)
    kernels = {
      "http://datacite.org/schema/kernel-2.1" => "kernel-2.1",
      "http://datacite.org/schema/kernel-2.2" => "kernel-2.2",
      "http://datacite.org/schema/kernel-3.0" => "kernel-3",
      "http://datacite.org/schema/kernel-3.1" => "kernel-3",
      "http://datacite.org/schema/kernel-3" => "kernel-3",
      "http://datacite.org/schema/kernel-4.0" => "kernel-4",
      "http://datacite.org/schema/kernel-4.1" => "kernel-4",
      "http://datacite.org/schema/kernel-4.2" => "kernel-4",
      "http://datacite.org/schema/kernel-4.3" => "kernel-4",
      "http://datacite.org/schema/kernel-4" => "kernel-4",
    }

    kernels[sv]
  end

  def validate_each(record, _attribute, value)
    kernel = get_valid_kernel(record.schema_version)
    return false if kernel.blank?

    if record.new_record? &&
        %w[
          http://datacite.org/schema/kernel-2.1
          http://datacite.org/schema/kernel-2.2
        ].include?(record.schema_version)
      record.errors[:xml] <<
        "DOI #{record.uid}: Schema #{record.schema_version} is no longer supported"
      return false
    end

    filepath =
      Bundler.rubygems.find_name("bolognese").first.full_gem_path +
      "/resources/#{kernel}/metadata.xsd"
    schema = Nokogiri::XML.Schema(open(filepath))

    schema.validate(Nokogiri.XML(value, nil, "UTF-8")).reduce(
      {},
    ) do |_sum, error|
      location, _level, source, text = error.message.split(": ", 4)
      line, column = location.split(":", 2)
      title = "DOI " + record.uid
      if line.present?
        title += ": " + text.to_s.strip + " at line #{line}, column #{column}"
      end
      source = source.split("}").last[0..-2] if line.present?
      source = schema_attributes(source) if source.present?
      record.errors[source.to_sym] << title
    end
  rescue Nokogiri::XML::SyntaxError => e
    line, column, _level, text = e.message.split(":", 4)
    message = text.strip + " at line #{line}, column #{column}"
    record.errors[:xml] << message
  end
end
