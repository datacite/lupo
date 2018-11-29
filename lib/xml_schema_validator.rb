class XmlSchemaValidator < ActiveModel::EachValidator
  # mapping of DataCite schema properties to database fields
  def schema_attributes(el)
    schema = {
      "creators" => "creator",
      "date" => "dates",
      "publicationYear" => "publication_year",
      "alternateIdentifiers" => "alternate_identifiers",
      "relatedIdentifiers" => "related_identifiers",
      "geoLocations" => "geo_locations",
      "rightsList" => "rights_list",
      "fundingReferences" => "funding_references",
      "version" => "version_info",
      "resource" => "xml"
    }

    schema[el] || el
  end

  def validate_each(record, attribute, value)
    return false unless record.schema_version.present?

    kernel = record.schema_version.split("/").last
    filepath = Bundler.rubygems.find_name('bolognese').first.full_gem_path + "/resources/#{kernel}/metadata.xsd"
    schema = Nokogiri::XML::Schema(open(filepath))
  
    schema.validate(Nokogiri::XML(value, nil, 'UTF-8')).reduce({}) do |sum, error|
      location, level, source, text = error.message.split(": ", 4)
      line, column = location.split(":", 2)
      title = text.to_s.strip + " at line #{line}, column #{column}" if line.present?
      source = source.split("}").last[0..-2] if line.present?
      source = schema_attributes(source) if source.present?  
      record.errors[source.to_sym] << title
    end
  rescue Nokogiri::XML::SyntaxError => e
    line, column, level, text = e.message.split(":", 4)
    message = text.strip + " at line #{line}, column #{column}"
    record.errors[:xml] << message
  end
end
