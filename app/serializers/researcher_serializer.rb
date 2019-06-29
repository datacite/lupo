class ResearcherSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :researchers
  set_id :uid
  
  attributes :name, :given_names, :family_name, :created_at, :updated_at
end
