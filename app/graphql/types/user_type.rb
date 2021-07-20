# frozen_string_literal: true

class UserType < BaseObject
  description "A user."

  field :uid, ID, null: false, description: "ID of a user."
  field :name,
        String,
        null: true,
        description: "Name of a user."
end
