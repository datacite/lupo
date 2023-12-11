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
    # Object is of different class if it comes from /activities/:uid
    if object.is_a? Activity
      changes = object.audited_changes
      action = object.action
    else
      changes = object._source.changes
      action = object._source.action
    end

    pub = changes&.dig("publisher")
    pub_obj = changes&.dig("publisher_obj")

    if params&.dig(:publisher) == "true"
      if pub_obj
        changes[:publisher] = pub_obj
      else
        changes[:publisher] = action == "update" ? [{ "name": pub[0] }, { "name": pub[1] }] : { "name": pub }
      end
    else
      if pub_obj
        changes[:publisher] = action == "update" ? [pub_obj[0]["name"], pub_obj[1]["name"]] : pub_obj["name"]
      end
    end

    changes.delete("publisher_obj") if pub_obj

    changes
  end

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
