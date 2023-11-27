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
    pub = changes.publisher
    pub_obj = changes.publisher_obj

    if params[:publisher] == "true"
      changes.publisher =
        if pub
          object._source.action == "update" ? [{ "name": pub[0] }, { "name": pub[1] }] : { "name": pub }
        else
          changes.publisher_obj
        end
    elsif pub_obj
      changes.publisher = object._source.action == "update" ? [pub_obj[0].name, pub_obj[1].name] : pub_obj.name
    end

    changes.delete("publisher_obj") if pub_obj

    changes
  end

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
