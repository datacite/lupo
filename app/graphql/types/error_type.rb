# frozen_string_literal: true

class ErrorType < BaseObject
  description "Information about errors"

  field :status, Int, null: false, description: "The error status."
  field :title, String, null: false, description: "The error description."
end
