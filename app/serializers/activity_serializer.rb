class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid
  
  attributes "prov:wasGeneratedBy", "prov:generatedAtTime", "prov:wasDerivedFrom", "prov:wasAttributedTo", :action, :version, :changes

  belongs_to :doi, record_type: :dois

  attribute "prov:wasDerivedFrom" do |object|
    url = Rails.env.production? ? "https://doi.org/" : "https://handle.test.datacite.org/"
    url + object.uid
  end

  attribute "prov:wasAttributedTo" do |object|
    return nil if object.username.blank?
    url = Rails.env.production? ? "https://api.datacite.org" : "https://api.test.datacite.org"
    object.username.include?(".") ? url + "/clients/" + object.username : url + "/providers/" + object.username
  end

  attribute "prov:wasGeneratedBy" do |object|
    url = Rails.env.production? ? "https://api.datacite.org" : "https://api.test.datacite.org"
    "#{url}/activities/#{object.request_uuid}"
  end

  attribute "prov:generatedAtTime" do |object|
    object.created
  end
end
