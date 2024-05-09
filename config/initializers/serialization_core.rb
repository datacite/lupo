# frozen_string_literal: true

# Monkey patch for jsonapi-serializer gem

module FastJsonapi
  module SerializationCore
    class_methods do
      def get_included_records(record, includes_list, known_included_objects, fieldsets, params = {})
        return unless includes_list.present?
        return [] unless relationships_to_serialize

        includes_list = parse_includes_list(includes_list)

        includes_list.each_with_object([]) do |include_item, included_records|
          relationship_item = relationships_to_serialize[include_item.first]

          next unless relationship_item&.include_relationship?(record, params)

          associated_objects = relationship_item.fetch_associated_object(record, params)

          if associated_objects.is_a?(Elasticsearch::Model::HashWrapper)
            associated_objects = OpenStruct.new(associated_objects)
          end

          included_objects = Array(associated_objects)

          next if included_objects.empty?

          static_serializer = relationship_item.static_serializer
          static_record_type = relationship_item.static_record_type

          included_objects.each do |inc_obj|
            serializer = static_serializer || relationship_item.serializer_for(inc_obj, params)
            record_type = static_record_type || serializer.record_type

            if include_item.last.any?
              serializer_records = serializer.get_included_records(inc_obj, include_item.last, known_included_objects, fieldsets, params)
              included_records.concat(serializer_records) unless serializer_records.empty?
            end

            code = "#{record_type}_#{serializer.id_from_record(inc_obj, params)}"
            next if known_included_objects.include?(code)

            known_included_objects << code

            included_records << serializer.record_hash(inc_obj, fieldsets[record_type], includes_list, params)
          end
        end
      end
    end
  end
end
