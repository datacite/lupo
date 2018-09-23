class RepositorySerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :repositories
  #cache_options enabled: true, cache_length: 24.hours

  attributes :repository_name, :repository_url, :repository_contacts, :description, :certificates, :types, 
    :additional_names, :subjects, :content_types, :provider_types, 
    :keywords, :institutions, :data_accesses, :data_uploads, :data_upload_licenses, :pid_systems,
    :apis, :pid_systems, :software, :start_date, :end_date, :created, :updated
end
