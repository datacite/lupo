module Types
  class ResourceTypeType < Types::BaseObject
    description "Information about types"

    field :ris, String, null: true, description: "RIS"
    field :bibtex, String, null: true, hash_key: "bibtex", description: "BibTex"
    field :citeproc, String, null: true, description: "Citeproc"
    field :schema_org, String, null: true, hash_key: "schemaOrg", description: "Schema.org"
    field :resource_type, String, null: true, hash_key: "resourceType", description: "Resource type"
    field :resource_type_general, String, null: true, hash_key: "resourceTypeGeneral", description: "Resource type general"
  end
end