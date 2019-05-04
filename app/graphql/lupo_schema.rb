require 'types/mutation_type'
require 'types/query_type'

class LupoSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
