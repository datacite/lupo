# frozen_string_literal: true

class EnrichedDoiSearchSerializer
  def self.serialize(hit, options = {})
    index = (hit[:index] || hit["_index"]).to_s
    source = hit[:source] || hit["_source"]
    object = OpenStruct.new(source)

    serializer =
      if index.start_with?("enriched_dois")
        EnrichedDoiSerializer
      else index.start_with?("dois")
        DataciteDoiSerializer
      end

    serializer.new(object, options).serializable_hash[:data]
  end

  def self.serialize_many(hits, options = {})
    {
      data: hits.map { |hit| serialize(hit, options) }.compact,
      meta: options[:meta],
      links: options[:links]
    }.compact
  end
end
