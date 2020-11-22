# frozen_string_literal: true

class EmploymentType < BaseObject
  description "Information about employments"

  field :organization_id,
        String,
        null: true, description: "The organization ID of the employment."
  field :organization_name,
        String,
        null: false, description: "The organization name of the employment."
  field :role_title,
        String,
        null: true, description: "The role title of the employment."
  field :start_date,
        GraphQL::Types::ISO8601DateTime,
        null: true, description: "Employment start date."
  field :end_date,
        GraphQL::Types::ISO8601DateTime,
        null: true, description: "Employment end date."
end
