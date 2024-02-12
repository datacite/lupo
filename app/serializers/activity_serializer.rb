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
    # Determine the source and action based on the object's type
    if object.is_a? Activity
      changes = object.audited_changes
      action = object.action
    else
      changes = object._source.changes
      action = object._source.action
    end

    # Extract publisher and publisher_obj from changes
    pub = changes&.dig("publisher")
    pub_obj = changes&.dig("publisher_obj")

    # Customize publisher information based on params[:publisher]
    if pub || pub_obj
      if params&.dig(:publisher) == "true"
        if pub_obj
          changes["publisher"] = pub_obj
        else
          changes["publisher"] =
            action == "update" ? [
              pub[0] ? { "name": pub[0] } : nil,
              pub[1] ? { "name": pub[1] } : nil
            ] : { "name": pub }
        end
      else
        if pub_obj
          changes["publisher"] =
            action == "update" ? [
              pub_obj[0] ? pub_obj[0]["name"] : nil,
              pub_obj[1] ? pub_obj[1]["name"] : nil
            ] : pub_obj["name"]
        else
          changes["publisher"] = pub
        end
      end
    end

    # Remove the not needed "publisher_obj" key
    changes.delete("publisher_obj")

    # Return the modified changes
    changes
  end

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
