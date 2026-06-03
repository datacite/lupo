# frozen_string_literal: true

class PrefixType < BaseObject
  description "Information about prefixes"

  field :id,
        ID,
        null: false,
        description: "Unique identifier for each prefix"

  def id
    object.is_a?(Hash) ? object["uid"] : object.uid
  end

  field :type, String, null: false, description: "The type of the item."

  def type
    "Prefix"
  end
end
