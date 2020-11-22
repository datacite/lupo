# frozen_string_literal: true

class ResourceType
  include Searchable

  attr_reader :id, :title, :updated_at

  def initialize(attributes, _options = {})
    @id = attributes.fetch("id").underscore.dasherize
    @title = attributes.fetch("title", nil)
    @updated_at = DATACITE_SCHEMA_DATE + "T00:00:00Z"
  end

  alias_attribute :updated, :updated_at

  def cache_key
    "resource_types/#{id}-#{updated_at}"
  end

  def as_indexed_json(_options = {})
    {
      "id" => id,
      "title" => title,
      "cache_key" => cache_key,
      "updated" => updated,
    }
  end

  def self.debug
    false
  end

  def self.get_data(_options = {})
    [
      { "id" => "audiovisual", "title" => "Audiovisual" },
      { "id" => "collection", "title" => "Collection" },
      { "id" => "data-paper", "title" => "DataPaper" },
      { "id" => "dataset", "title" => "Dataset" },
      { "id" => "event", "title" => "Event" },
      { "id" => "image", "title" => "Image" },
      { "id" => "interactive-resource", "title" => "InteractiveResource" },
      { "id" => "model", "title" => "Model" },
      { "id" => "physical-object", "title" => "PhysicalObject" },
      { "id" => "service", "title" => "Service" },
      { "id" => "software", "title" => "Software" },
      { "id" => "sound", "title" => "Sound" },
      { "id" => "text", "title" => "Text" },
      { "id" => "workflow", "title" => "Workflow" },
      { "id" => "other", "title" => "Other" },
    ]
  end

  def self.parse_data(items, options = {})
    if options[:id]
      item = items.detect { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      if options[:query]
        items =
          items.select do |i|
            (
              i.fetch("title", "").downcase +
                i.fetch("description", "").downcase
            ).
              include?(options[:query])
          end
      end

      page = (options.dig(:page, :number) || 1).to_i
      per_page =
        if options.dig(:page, :size) &&
            (1..1_000).cover?(options.dig(:page, :size).to_i)
          options.dig(:page, :size).to_i
        else
          25
        end
      total_pages = (items.length.to_f / per_page).ceil

      meta = { total: items.length, "total-pages" => total_pages, page: page }

      offset = (page - 1) * per_page
      items = items[offset...offset + per_page] || []

      { data: parse_items(items), meta: meta }
    end
  end
end
