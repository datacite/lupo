class RepositorySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :repositories
  cache_options enabled: true, cache_length: 24.hours

  attributes :name, :additional_name, :description, :repository_url, :repository_contact, :subject, :repository_software, :created, :updated
end
