# frozen_string_literal: true

class ResourceTypeType < BaseObject
  description "Information about types"

  field :ris, String, null: true, description: "RIS"
  field :bibtex, String, null: true, description: "BibTex"

  def bibtex
    object["bibtex"]
  end

  field :citeproc, String, null: true, description: "Citeproc"
  field :schema_org,
        String,
        null: true, description: "Schema.org"

  def schema_org
    object["schemaOrg"]
  end

  field :resource_type,
        String,
        null: true, description: "Resource type"

  def resource_type
    object["resourceType"]
  end

  field :resource_type_general,
        String,
        null: true,
        description: "Resource type general"

  def resource_type_general
    object["resourceTypeGeneral"]
  end
end
