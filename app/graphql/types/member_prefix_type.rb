# frozen_string_literal: true

class MemberPrefixType < BaseObject
  description "Information about member prefixes"

  field :id,
        ID,
        null: false,
        description: "Unique identifier for each provider prefix"

  def id
    object.uid
  end

  field :type, String, null: false, description: "The type of the item."
  field :name,
        String,
        null: false, description: "Provider prefix name"

  def name
    object.prefix_id
  end

  def type
    "MemberPrefix"
  end
end
