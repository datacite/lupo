# frozen_string_literal: true

class ClaimType < BaseObject
  description "A claim."

  field :id, ID, null: false, description: "The ID of the claim."
  field :type, String, null: false, description: "The type of the item."
  field :source_id, String, null: false, description: "The source of the claim."
  field :state, String, null: false, description: "The state of the claim."
  field :claim_action,
        String,
        null: false, description: "The action for the claim."
  field :claimed,
        GraphQL::Types::ISO8601DateTime,
        null: true, description: "Date and time when claim was done."
  field :error_messages,
        [ErrorType],
        null: true, description: "Optional error messages."

  def type
    "Claim"
  end
end
