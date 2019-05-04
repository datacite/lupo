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
  end
end
