# frozen_string_literal: true

class ApiType < BaseObject
  description "Information"

  field :url, String, null: false, description: "URL"
  field :type, String, null: true, description: "Type"
end
