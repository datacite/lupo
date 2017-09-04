class ResourceType < Base
  attr_reader :id, :title, :updated_at

  def initialize(attributes, options={})
    @id = attributes.fetch("id").underscore.dasherize
    @title = attributes.fetch("title", nil)
    @updated_at = DATACITE_SCHEMA_DATE + "T00:00:00Z"
  end

  def self.get_query_url(options={})
    "http://schema.test.datacite.org/meta/kernel-#{DATACITE_VERSION}/include/datacite-resourceType-v#{DATACITE_VERSION}.xsd"
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result['errors']
    result = result.to_h
    items = result.fetch(:body, {}).fetch("data", {}).fetch("schema", {}).fetch("simpleType", {}).fetch('restriction', {}).fetch('enumeration', [])
    items = items.map do |item|
      id = item.fetch("value").underscore.dasherize

      { "id" => id, "title" => id.underscore.humanize }
    end

    if options[:id]
      item = items.find { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      { data: parse_items(items), meta: { total: items.length } }
    end
  end
end
