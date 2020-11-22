# frozen_string_literal: true

class SoftwareApplicationType < BaseObject
  description "A software application."

  field :name, String, null: true, description: "The name of the item."
  field :description,
        String,
        null: true, description: "A description of the item."
  field :software_version,
        String,
        null: true, description: "Version of the software instance."
  field :url, String, null: true, description: "URL of the item."
end
