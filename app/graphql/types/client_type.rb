module Types
  class ClientType < Types::BaseObject
    description "Information about clients"

    field :id, ID, null: false, hash_key: 'uid', description: "Unique identifier for each client"
    field :name, String, null: false, description: "Client name"
    field :description, String, null: true, description: "Description of the client"
    field :contact_name, String, null: true, description: "Client contact name"
    field :contact_email, String, null: true, description: "Client contact email"
  end
end
