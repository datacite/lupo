# frozen_string_literal: true

class ErrorType < BaseObject
  description "Information about errors"

  field :status, Int, null: true, description: "The error status."
  field :source, String, null: true, description: "The error source."
  field :title, String, null: false, description: "The error description."
end
