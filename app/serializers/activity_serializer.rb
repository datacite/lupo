class ActivitySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :activities
  set_id :request_uuid
  
  attributes :doi, :username, :action, :changes, :created

  belongs_to :doi, record_type: :dois

  attribute :doi do |object|
    object.uid
  end
end