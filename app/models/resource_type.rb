class ResourceType
  include Searchable 

  attr_reader :id, :title, :updated_at

  def initialize(attributes, options={})
    @id = attributes.fetch("id").underscore.dasherize
    @title = attributes.fetch("title", nil)
    @updated_at = DATACITE_SCHEMA_DATE + "T00:00:00Z"
  end

  def cache_key
    "resource_type/#{id}-#{updated_at}"
  end

  def self.debug
    false
  end

  def self.get_data(options = {})
    [
        {
            'id' => 'audiovisual',
            'title' => 'Audiovisual'
        },
        {
            'id' => 'collection',
            'title' => 'Collection'
        },
        {
            'id' => 'data-paper',
            'title' => 'DataPaper'
        },
        {
            'id' => 'dataset',
            'title' => 'Dataset'
        },
        {
            'id' => 'event',
            'title' => 'Event'
        },
        {
            'id' => 'image',
            'title' => 'Image'
        },
        {
            'id' => 'interactive-resource',
            'title' => 'InteractiveResource'
        },
        {
            'id' => 'model',
            'title' => 'Model'
        },
        {
            'id' => 'physical-object',
            'title' => 'PhysicalObject'
        },
        {
            'id' => 'service',
            'title' => 'Service'
        },
        {
            'id' => 'software',
            'title' => 'Software'
        },
        {
            'id' => 'sound',
            'title' => 'Sound'
        },
        {
            'id' => 'text',
            'title' => 'Text'
        },
        {
            'id' => 'workflow',
            'title' => 'Workflow'
        },
        {
            'id' => 'other',
            'title' => 'Other'
        }
    ]
  end

  def self.parse_data(items, options={})
    if options[:id]
      item = items.find { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      { data: parse_items(items), meta: { total: items.length } }
    end
  end
end
