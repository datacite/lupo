class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid
  
  attributes "prov:wasGeneratedBy", "prov:generatedAtTime", "prov:wasDerivedFrom", "prov:wasAttributedTo", :action, :version, :changes

  attribute "prov:wasDerivedFrom" do |object|
    object.was_derived_from
  end

  attribute "prov:wasAttributedTo" do |object|
    object.was_attributed_to
  end

  attribute "prov:wasGeneratedBy" do |object|
    object.was_generated_by
  end

  attribute "prov:generatedAtTime" do |object|
    object.created
  end
end
