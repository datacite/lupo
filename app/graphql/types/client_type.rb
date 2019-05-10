# frozen_string_literal: true

class ClientType < GraphQL::Schema::Object
  description "Information about clients"

  field :id, ID, null: false, hash_key: "uid", description: "Unique identifier for each client"
  field :name, String, null: false, description: "Client name"
  field :description, String, null: true, description: "Description of the client"
  field :contact_name, String, null: true, description: "Client contact name"
  field :contact_email, String, null: true, description: "Client contact email"
  field :prefixes, [PrefixType], null: false, description: "Prefixes managed by the client"  do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :datasets, [Types::DatasetType], null: false, description: "Datasets managed by the client" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  field :publications, [PublicationType], null: false, description: "Publications managed by the client" do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def prefixes(**args)
    collection = object.prefixes
    collection = collection.query(args[:query]) if args[:query].present?
    collection.page(1).per(args[:first])
  end

  def datasets(**args)
    Doi.query(args[:query], client_id: object.uid, resource_type_id: "Dataset", page: { number: 1, size: args[:first] })
  end

  def publications(**args)
    Doi.query(args[:query], client_id: object.uid, resource_type_id: "Text", page: { number: 1, size: args[:first] })
  end
end
