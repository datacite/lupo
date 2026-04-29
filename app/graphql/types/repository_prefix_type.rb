# frozen_string_literal: true

class RepositoryPrefixType < BaseObject
  description "Information about repository prefixes"

  field :id,
        ID,
        null: false,
        description: "Unique identifier for each repository prefix"

  def id
    object.uid
  end

  field :type, String, null: false, description: "The type of the item."
  field :name,
        String,
        null: false,
        description: "Repository prefix name"

  def name
    object.prefix_id
  end

  def type
    "RepositoryPrefix"
  end
end
