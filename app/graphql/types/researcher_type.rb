# frozen_string_literal: true

class ResearcherType < BaseObject
  description "Information about researchers"

  field :id, ID, null: true, description: "ORCID ID"
  field :name, String, null: true, description: "Researcher name"
  field :name_type, String, null: true, hash_key: "nameType", description: "The type of name"
  field :given_names, String, null: true, description: "User given names"
  field :family_name, String, null: true, description: "Researcher family name"

  def id
    object.uid ? "https://orcid.org/#{object.uid}" : object.id
  end

  def name
    object.name
  end
end
