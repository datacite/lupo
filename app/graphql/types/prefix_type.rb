module Types
  class PrefixType < Types::BaseObject
    description "Information about prefixes"

    field :id, ID, null: false, hash_key: 'prefix', description: "Unique identifier for each prefix"
  end
end
