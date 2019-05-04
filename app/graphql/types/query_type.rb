module Types
  class QueryType < Types::BaseObject
    field :members, [Types::MemberType], null: false

    def members
      Provider.query(nil)
    end

    field :member, Types::MemberType, null: false do
      argument :id, ID, required: true
    end

    def member(id:)
      Provider.find_by_id(id).first
    end

    field :clients, [Types::ClientType], null: false

    def clients
      Client.query(nil)
    end

    field :client, Types::ClientType, null: false do
      argument :id, ID, required: true
    end

    def client(id:)
      Client.find_by_id(id).first
    end

    field :prefixes, [Types::PrefixType], null: false

    def prefixes
      Prefix.all
    end

    field :prefix, Types::PrefixType, null: false do
      argument :id, ID, required: true
    end

    def prefix(id:)
      Prefix.where(prefix: id).first
    end
  end
end
