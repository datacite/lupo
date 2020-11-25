# frozen_string_literal: true

class PrefixType < BaseObject
  description "Information about prefixes"

  field :id,
        ID,
        null: false,
        hash_key: "uid",
        description: "Unique identifier for each prefix"
  field :type, String, null: false, description: "The type of the item."

  def type
    "Prefix"
  end
end
