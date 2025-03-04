# frozen_string_literal: true

class ReferenceRepositorySerializer
  include JSONAPI::Serializer

  set_key_transform :camel_lower
  set_type :reference_repositories
  set_id :uid

  attributes :client_id,
             :re3doi,
             :re3data_url,
             :name,
             :alternate_name,
             :description,
             :pid_system,
             :url,
             :keyword,
             :contact,
             :language,
             :certificate,
             :data_access,
             :data_upload,
             :provider_type,
             :repository_type,
             :software,
             :subject,
             :re3_created_at,
             :re3_updated_at,
             :client_created_at,
             :client_updated_at,
             :provider_id,
             :provider_id_and_name,
             :year,
             :created_at,
             :updated_at
end
