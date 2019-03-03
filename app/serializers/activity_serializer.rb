class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid
  
  attributes "prov:wasGeneratedBy", "prov:generatedAtTime", "prov:WasDerivedFrom", "prov:wasAttributedTo", "prov:type", :changes

  belongs_to :doi, record_type: :dois

  attribute "prov:WasDerivedFrom" do |object|
    object.uid
  end

  attribute "prov:wasAttributedTo" do |object|
    object.username
  end

  attribute "prov:wasGeneratedBy" do |object|
    url = Rails.env.production? ? "https://api.datacite.org" : "https://api.test.datacite.org"
    "#{url}/activities/#{object.request_uuid}"
  end

  attribute "prov:generatedAtTime" do |object|
    object.created
  end

  attribute "prov:type" do |object|
    case object.action
    when "create" then "prov:primarySource"
    when "update" then "prov:Revision"
    end
  end
end
