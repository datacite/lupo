# frozen_string_literal: true

class V3::ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid

  attributes "prov:wasGeneratedBy",
             "prov:generatedAtTime",
             "prov:wasDerivedFrom",
             "prov:wasAttributedTo",
             :action,
             :version,
             :changes

  attribute "prov:wasDerivedFrom", &:was_derived_from

  attribute "prov:wasAttributedTo", &:was_attributed_to

  attribute "prov:wasGeneratedBy", &:was_generated_by

  attribute "prov:generatedAtTime", &:created
end
