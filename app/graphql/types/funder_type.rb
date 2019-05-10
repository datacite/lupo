# frozen_string_literal: true

module Types
  class FunderType < Types::BaseObject
    description "Information about funders"

    field :id, ID, null: false, description: "Crossref Funder ID"
    field :name, String, null: false, description: "Funder name"
    field :alternate_name, [String], null: true, description: "Alternate funder names"
    field :country, String, null: true, description: "Country where funder is located"
    field :date_modified, String, null: false, description: "Date information was last updated"
  end
end
