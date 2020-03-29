class ClientPrefixType < BaseObject
  description "Information about client prefixes"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each client prefix"
  field :type, String, null: false, description: "The type of the item."
  field :name, String, null: false, hash_key: "prefix_id", description: "Client prefix name"

  def type
    "ClientPrefix"
  end
end
