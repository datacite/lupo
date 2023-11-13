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

    ret = changes

    if object._source.action == "update"
      if pub || pub_obj
        if params[:publisher] == "true"
          if !pub_obj
            changes.publisher =
              [
                { "name": pub[0] },
                { "name": pub[1] },
              ]
          else
            changes.publisher = changes.publisher_obj
          end
        else
          if !pub
            changes.publisher = [ pub_obj[0].name, pub_obj[1].name ]
          end
        end

        ret = changes
      end
    elsif object._source.action == "create"
      if pub || pub_obj
        if params[:publisher] == "true"
          if !pub_obj
            changes.publisher = { "name": pub }
          else
            changes.publisher = changes.publisher_obj
          end
        else
          if !pub
            changes.publisher = pub_obj.name
          end
        end

        ret = changes
      end
    end

    if pub_obj
      changes.delete("publisher_obj")
    end

    ret
  end

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
