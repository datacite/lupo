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
        items = items.select { |i| (i.fetch("title", "").downcase + i.fetch("description", "").downcase).include?(options[:query]) } if options[:query]

        page = (options.dig(:page, :number) || 1).to_i
        per_page = options.dig(:page, :size) && (1..1000).include?(options.dig(:page, :size).to_i) ? options.dig(:page, :size).to_i : 25
        total_pages = (items.length.to_f / per_page).ceil

        meta = { total: items.length, "total-pages" => total_pages, page: page }
        
        offset = (page - 1) * per_page
        items = items[offset...offset + per_page] || []

      { data: parse_items(items), meta: meta }
    end
  end
end
