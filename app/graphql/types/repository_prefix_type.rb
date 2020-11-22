# frozen_string_literal: true

class RepositoryPrefixType < BaseObject
  description "Information about repository prefixes"

  field :id,
        ID,
        null: false,
        hash_key: "uid",
        description: "Unique identifier for each repository prefix"
  field :type, String, null: false, description: "The type of the item."
  field :name,
        String,
        null: false,
        hash_key: "prefix_id",
        description: "Repository prefix name"

  def type
    "RepositoryPrefix"
  end
end
