# frozen_string_literal: true

class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid

  attributes "prov:wasGeneratedBy",
             "prov:generatedAtTime",
             "prov:wasDerivedFrom",
             "prov:wasAttributedTo",
             :action,
             :version

  attribute :changes do |object, params|
    changes = object._source.changes
    publisher = changes.try(:publisher)
    publisher_obj = changes.try(:publisher_obj)
    changes.delete(:publisher_obj) if publisher_obj

    if publisher || publisher_obj
      original_pub =
        if publisher_obj.is_a?(Array)
          publisher_obj[0]
        elsif publisher.is_a?(Array)
          publisher[0].present? ? { "name" => publisher[0] } : nil
        elsif publisher_obj.is_a?(Hash)
          publisher_obj
        elsif publisher.is_a?(String)
          { "name" => publisher }
        end

      changed_pub =
        if publisher_obj.is_a?(Array)
          publisher_obj[1]
        elsif publisher.is_a?(Array)
          publisher[1].present? ? { "name" => publisher[1] } : nil
        end

      case object._source.action
      when "update"
        if params&.dig(:publisher) == "true"
          changes.publisher =
          [
            original_pub,
            changed_pub
          ]
        else
          changes.publisher = [
            original_pub.present? ? original_pub.fetch("name", nil) : nil,
            changed_pub.present? ? changed_pub.fetch("name", nil) : nil,
          ]
        end
      when "create"
        if params&.dig(:publisher) == "true"
          changes.publisher = original_pub
        else
          changes.publisher = original_pub.fetch("name", nil)
        end
      end
    end

    changes
  end

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
