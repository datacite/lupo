# frozen_string_literal: true

class EmploymentType < BaseObject
  description "Information about employments"

  field :organizationId, String, null: true, description: "The organization ID of the employment."
  field :organizationName, String, null: false, description: "The organization name of the employment."
  field :roleTitle, String, null: true, description: "The role title of the employment."
  field :startDate, GraphQL::Types::ISO8601DateTime, null: true, description: "Employment start date."
  field :endDate, GraphQL::Types::ISO8601DateTime, null: true, description: "Employment end date."
end
