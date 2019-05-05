module Types
  class QueryType < Types::BaseObject
    field :members, [Types::MemberType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 100
    end

    def members(query: nil, first: nil)
      Provider.query(query, page: { number: 1, size: first })
    end

    field :member, Types::MemberType, null: false do
      argument :id, ID, required: true
    end

    def member(id:)
      Provider.find_by_id(id).first
    end

    field :clients, [Types::ClientType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 100
    end

    def clients(query: nil, first: nil)
      Client.query(query, page: { number: 1, size: first })
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

    field :funders, [Types::FunderType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 100
    end

    def funders(query: nil, first: nil)
      Funder.query(query, limit: first)
    end

    field :funder, Types::FunderType, null: false do
      argument :id, ID, required: true
    end

    def funder(id:)
      Funder.find_by_id(id).first
    end

    field :researcher, Types::ResearcherType, null: false do
      argument :id, ID, required: true
    end

    def researcher(id:)
      Researcher.find_by_id(id).first
    end
  end
end
