# frozen_string_literal: true

class MemberPrefixType < BaseObject
  description "Information about member prefixes"

  field :id,
        ID,
        null: false,
        hash_key: "uid",
        description: "Unique identifier for each provider prefix"
  field :type, String, null: false, description: "The type of the item."
  field :name,
        String,
        null: false, hash_key: "prefix_id", description: "Provider prefix name"

  def type
    "MemberPrefix"
  end
end
