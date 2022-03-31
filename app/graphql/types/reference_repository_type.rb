
# frozen_string_literal: true

class ReferenceRepositoryType < BaseObject
  description "Information about repositories"
  field :uid,
        ID,
        null: false,
        description: "Unique identifier for each repository"
  field :type,
        String,
        null: false,
        description: "The type of the item."
  field :client_id,
        ID,
        null: true,
        description: "The unique identifier for the client repository"
  field :re3data_doi,
        ID,
        hash_key: "re3doi",
        null: true, description: "The re3data doi for the repository"
  field :name,
        String,
        null: false,
        description: "Repository name"
  field :alternate_name,
        [String],
        null: true,
        description: "Repository alternate names"
  field :description,
        String,
        null: true,
        description: "Description of the repository"
  field :url,
        Url,
        null: true,
        description: "The homepage of the repository"
  field :re3data_url,
        Url,
        null: true,
        description: "URL of the data catalog."
  field :software,
        [String],
        null: true,
        description: "The name of the software that is used to run the repository"
  field :repository_type,
        [String],
        null: true,
        description: "The repository type(s)"
  field :certificate,
        [String],
        null: true,
        description: "The certificate(s) for the repository"
  field :language,
        [String],
        null: true,
        description: "The langauge of the repository"
  field :provider_type,
        [String],
        null: true,
        description: "The type(s) of Provider"
  field :pid_system,
        [String],
        null: true,
        description: "PID Systems"
  field :data_access,
        [TextRestrictionType],
        null: true,
        description: "Data accesses"
  field :data_upload,
        [TextRestrictionType],
        null: true,
        description: "Data uploads"
  field :subject,
        [DefinedTermType],
        null: true,
        description: "Subject areas covered by the data catalog."
  field :contact,
        [String],
        null: true,
        description: "Repository contact information"

  def type
    "Repository"
  end
end
