# frozen_string_literal: true

module Types
  class OrganizationType < Types::BaseObject
    description "Information about organizations"

    field :id, ID, null: false, description: "ROR ID"
    field :name, String, null: false, description: "Organization name"
    field :aliases, [String], null: true, description: "Aliases for organization name"
    field :acronyms, [String], null: true, description: "Acronyms for organization name"
    field :labels, [::Types::LabelType], null: true, description: "Labels for organization name"
    field :links, [String], null: true, description: "Links for organization"
    field :wikipedia_url, String, null: true, description: "Wikipedia URL for organization"
    field :country, Types::CountryType, null: true, description: "Country where organization is located"
    field :isni, [String], null: true, description: "ISNI identifiers for organization"
    field :fund_ref, [String], null: true, description: "Crossref Funder ID identifiers for organization"
    field :wikidata, [String], null: true, description: "Wikidata identifiers for organization"
    field :grid, [String], null: true, description: "GRID identifiers for organization"
  end
end
