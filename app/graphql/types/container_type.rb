# frozen_string_literal: true

class ContainerType < BaseObject
  description "Information about containers for content."

  field :identifier_type, String, null: true, hash_key: "identifierType", description: "The type of identifier."
  field :identifier, String, null: true, description: "The value of the identifier."
  field :type, String, null: true, description: "Container type."
  field :title, String, null: true, description: "Container title."
  field :volume, String, null: true, description: "Volume."
  field :issue, String, null: true, description: "Issue."
  field :first_page, String, null: true, description: "First page."
  field :last_page, String, null: true, description: "Last page."
end
